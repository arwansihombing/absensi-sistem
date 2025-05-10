import os
import cv2
import numpy as np
import logging
import yaml
from typing import Dict, List
from queue import Queue
from threading import Thread
from tenacity import retry, stop_after_attempt, wait_exponential
from cryptography.fernet import Fernet
from prometheus_client import Counter, Gauge, start_http_server
import paho.mqtt.client as mqtt

class StreamConfig:
    def __init__(self, config_path: str):
        self.config = self._load_encrypted_config(config_path)
        
    def _load_encrypted_config(self, config_path: str) -> dict:
        key = os.environ.get('CONFIG_KEY')
        f = Fernet(key)
        with open(config_path, 'rb') as file:
            encrypted_data = file.read()
            decrypted_data = f.decrypt(encrypted_data)
            return yaml.safe_load(decrypted_data)

class CircularFrameBuffer:
    def __init__(self, maxsize: int = 30):
        self.buffer = Queue(maxsize=maxsize)
        
    def put(self, frame: np.ndarray) -> None:
        if self.buffer.full():
            self.buffer.get()
        self.buffer.put(frame)
        
    def get(self) -> np.ndarray:
        return self.buffer.get() if not self.buffer.empty() else None

class RTSPStream:
    def __init__(self, stream_id: str, url: str, buffer_size: int = 30):
        self.stream_id = stream_id
        self.url = url
        self.frame_buffer = CircularFrameBuffer(buffer_size)
        self.active = True
        self.metrics = {
            'frames_processed': Counter(f'frames_processed_{stream_id}', 'Frames processed'),
            'stream_latency': Gauge(f'stream_latency_{stream_id}', 'Stream latency in ms')
        }
        
    @retry(stop=stop_after_attempt(5), wait=wait_exponential(multiplier=1, min=4, max=60))
    def connect(self) -> None:
        # Configure GStreamer pipeline for hardware acceleration
        pipeline = (
            f'rtspsrc location={self.url} latency=0 ! '
            'rtph264depay ! '
            'h264parse ! '
            'v4l2h264dec ! '
            'video/x-raw ! '
            'appsink'
        )
        self.cap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)
        
        if not self.cap.isOpened():
            raise ConnectionError(f"Failed to connect to stream {self.url}")
    
    def start(self) -> None:
        self.thread = Thread(target=self._capture_loop)
        self.thread.daemon = True
        self.thread.start()
        
    def _capture_loop(self) -> None:
        while self.active:
            ret, frame = self.cap.read()
            if ret:
                self.frame_buffer.put(frame)
                self.metrics['frames_processed'].inc()
            else:
                self.connect()

class StreamManager:
    def __init__(self, config_path: str):
        self.config = StreamConfig(config_path)
        self.streams: Dict[str, RTSPStream] = {}
        self.mqtt_client = self._setup_mqtt()
        start_http_server(8000)  # Metrics endpoint
        
    def _setup_mqtt(self) -> mqtt.Client:
        client = mqtt.Client()
        client.username_pw_set(
            self.config.config['mqtt']['username'],
            self.config.config['mqtt']['password']
        )
        client.connect(
            self.config.config['mqtt']['host'],
            self.config.config['mqtt']['port']
        )
        return client
        
    def add_stream(self, stream_id: str, url: str) -> None:
        if stream_id not in self.streams:
            stream = RTSPStream(stream_id, url)
            stream.connect()
            stream.start()
            self.streams[stream_id] = stream
            
    def remove_stream(self, stream_id: str) -> None:
        if stream_id in self.streams:
            self.streams[stream_id].active = False
            del self.streams[stream_id]
            
    def get_frame(self, stream_id: str) -> np.ndarray:
        if stream_id in self.streams:
            return self.streams[stream_id].frame_buffer.get()
        return None

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    manager = StreamManager('config.yml')
    
    # Add test streams
    test_streams = [
        ("cam1", "rtsp://camera1.local:554/stream"),
        ("cam2", "rtsp://camera2.local:554/stream"),
        ("cam3", "rtsp://camera3.local:554/stream"),
        ("cam4", "rtsp://camera4.local:554/stream")
    ]
    
    for stream_id, url in test_streams:
        manager.add_stream(stream_id, url)
    
    try:
        while True:
            for stream_id in manager.streams:
                frame = manager.get_frame(stream_id)
                if frame is not None:
                    # Process frame or send to inference engine
                    manager.mqtt_client.publish(
                        f"frames/{stream_id}",
                        cv2.imencode('.jpg', frame)[1].tobytes()
                    )
    except KeyboardInterrupt:
        for stream in manager.streams.values():
            stream.active = False