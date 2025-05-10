# Use ARM64 base image
FROM arm64v8/ubuntu:20.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libopencv-dev \
    python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
WORKDIR /app
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy AI models
COPY models/ /app/models/

# Copy application code
COPY . /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV NPU_VISIBLE_DEVICES=all
ENV MODEL_PATH=/app/models

# Run the application
CMD ["python3", "inference_engine.py"]