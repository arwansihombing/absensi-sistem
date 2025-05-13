# Enable BuildKit features
# syntax=docker/dockerfile:1.4

# Multi-stage build untuk mengoptimalkan ukuran image

# Stage 1: Base image dengan dependencies umum
FROM --platform=$BUILDPLATFORM ubuntu:20.04 as base

# Setup build arguments untuk multi-platform support
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies sistem
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    python3-gst-1.0 \
    libopencv-dev \
    python3-opencv \
    redis-server \
    mosquitto \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Build untuk Stream Manager
FROM --platform=$BUILDPLATFORM base as stream-manager
WORKDIR /app/stream-manager
COPY services/stream-manager/requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install -r requirements.txt
COPY services/stream-manager/ .

# Stage 3: Build untuk Inference Engine
FROM --platform=$BUILDPLATFORM base as inference-engine
WORKDIR /app/inference-engine
COPY services/inference-engine/requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install -r requirements.txt
COPY services/inference-engine/ .

# Stage 4: Final image dengan platform-specific optimizations
FROM --platform=$BUILDPLATFORM base

# Copy dari stage sebelumnya dengan platform awareness
COPY --from=stream-manager /app/stream-manager /app/stream-manager
COPY --from=inference-engine /app/inference-engine /app/inference-engine

# Install TimescaleDB dengan cache mounting
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y postgresql postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Setup direktori dan permissions dengan security best practices
RUN mkdir -p /mosquitto/data /mosquitto/log \
    && chown -R mosquitto:mosquitto /mosquitto \
    && chmod -R 755 /mosquitto

# Copy konfigurasi dengan explicit permissions
COPY --chown=mosquitto:mosquitto mosquitto.conf /etc/mosquitto/mosquitto.conf

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