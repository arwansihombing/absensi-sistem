# Multi-stage build untuk mengoptimalkan ukuran image

# Stage 1: Base image dengan dependencies umum
FROM nvidia/cuda:11.4.0-runtime-ubuntu20.04 as base

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies sistem
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    redis-server \
    mosquitto \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Build untuk Stream Manager
FROM base as stream-manager
WORKDIR /app/stream-manager
COPY services/stream-manager/requirements.txt .
RUN pip3 install -r requirements.txt
COPY services/stream-manager/ .

# Stage 3: Build untuk Inference Engine
FROM base as inference-engine
WORKDIR /app/inference-engine
COPY services/inference-engine/requirements.txt .
RUN pip3 install -r requirements.txt
COPY services/inference-engine/ .

# Stage 4: Final image
FROM base

# Copy dari stage sebelumnya
COPY --from=stream-manager /app/stream-manager /app/stream-manager
COPY --from=inference-engine /app/inference-engine /app/inference-engine

# Install TimescaleDB
RUN apt-get update && apt-get install -y postgresql postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Setup direktori dan permissions
RUN mkdir -p /mosquitto/data /mosquitto/log \
    && chown -R mosquitto:mosquitto /mosquitto

# Copy konfigurasi
COPY mosquitto.conf /etc/mosquitto/mosquitto.conf

# Setup environment variables
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
ENV NPU_VISIBLE_DEVICES=all
ENV POSTGRES_PASSWORD=secure_password

# Expose ports
EXPOSE 1883 9001 8000 3000

# Copy script startup
COPY start-services.sh /start-services.sh
RUN chmod +x /start-services.sh

CMD ["/start-services.sh"]