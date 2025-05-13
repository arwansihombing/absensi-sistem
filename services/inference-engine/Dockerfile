# Use ARM64 base image
FROM arm64v8/ubuntu:20.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    libopencv-dev \
    python3-opencv \
    libcairo2-dev \
    pkg-config \
    libgirepository1.0-dev \
    gir1.2-gtk-3.0 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m appuser

# Create and activate virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt /app/
WORKDIR /app
RUN pip3 install --no-cache-dir Cython wheel setuptools
RUN pip3 install --no-cache-dir -r requirements.txt

# Switch to non-root user
USER appuser

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