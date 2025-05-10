# Use ARM64 base image
FROM arm64v8/ubuntu:20.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    python3-gst-1.0 \
    libmali-rk-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
WORKDIR /app
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV GST_DEBUG=3

# Run the application
CMD ["python3", "stream_manager.py"]