#!/bin/bash

# Set variables
DOCKER_USERNAME="arwansihombing"
IMAGE_NAME="absensi-system"
TAG="latest"

# Build the combined image
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:$TAG -f Dockerfile.combined .

# Login to Docker Hub (akan meminta password)
docker login -u $DOCKER_USERNAME

# Push image ke Docker Hub
docker push $DOCKER_USERNAME/$IMAGE_NAME:$TAG

echo "Image berhasil di-push ke Docker Hub: $DOCKER_USERNAME/$IMAGE_NAME:$TAG"