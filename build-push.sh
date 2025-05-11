#!/bin/bash

# Set variables
DOCKER_USERNAME="arwansihombing"
IMAGE_NAME="absensi-system"
TAG="latest"

# Pastikan Docker terinstal
if ! command -v docker &> /dev/null; then
    echo "Docker belum terinstal. Menginstal Docker terlebih dahulu..."
    # Jalankan script instalasi Docker
    bash ./install-docker.sh
    # Tunggu sebentar agar Docker service siap
    sleep 5
    # Verifikasi instalasi
    if ! command -v docker &> /dev/null; then
        echo "Gagal menginstal Docker. Silakan instal Docker secara manual."
        exit 1
    fi
fi

# Install dependensi minimum yang diperlukan
echo "Installing minimum dependencies..."
sudo apt-get update && sudo apt-get install -y \
    python3 \
    python3-pip \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    supervisor

# Bersihkan cache apt
sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Build the combined image
echo "Building Docker image..."
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:$TAG -f Dockerfile.combined .

# Login to Docker Hub (akan meminta password)
echo "Logging in to Docker Hub..."
docker login -u $DOCKER_USERNAME

# Push image ke Docker Hub
echo "Pushing image to Docker Hub..."
docker push $DOCKER_USERNAME/$IMAGE_NAME:$TAG

echo "Image berhasil di-push ke Docker Hub: $DOCKER_USERNAME/$IMAGE_NAME:$TAG"