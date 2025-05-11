#!/bin/bash

# Fungsi untuk mengecek apakah Docker sudah terinstal
check_docker() {
    if command -v docker &> /dev/null; then
        echo "Docker sudah terinstal"
        return 0
    else
        echo "Docker belum terinstal"
        return 1
    fi
}

# Fungsi untuk menginstal Docker
install_docker() {
    echo "Menginstal Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install packages untuk mengizinkan apt menggunakan repository melalui HTTPS
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Tambahkan Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up repository Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package list lagi dan install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Start dan enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    # Tambahkan user ke grup docker
    sudo usermod -aG docker $USER

    echo "Docker berhasil diinstal!"
    echo "Silakan logout dan login kembali agar perubahan grup docker berlaku"
}

# Main script
if ! check_docker; then
    install_docker
fi