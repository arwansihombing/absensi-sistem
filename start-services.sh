#!/bin/bash

# Start PostgreSQL service
service postgresql start

# Start Redis server
redis-server --daemonize yes

# Start Mosquitto broker
mosquitto -c /etc/mosquitto/mosquitto.conf -d

# Start Stream Manager
cd /app/stream-manager
python3 main.py &

# Start Inference Engine
cd /app/inference-engine
python3 main.py &

# Keep container running
tail -f /dev/null