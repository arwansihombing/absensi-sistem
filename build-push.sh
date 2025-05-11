#!/bin/bash

# Set variables
DOCKER_USERNAME="arwansihombing"
IMAGE_NAME="absensi-system"
TAG="latest"

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