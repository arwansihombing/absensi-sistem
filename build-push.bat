@echo off
setlocal enabledelayedexpansion

:: Set variables
set DOCKER_USERNAME=arwansihombing
set IMAGE_NAME=absensi-system
set TAG=latest
set DOCKERFILE=Dockerfile.combined

:: Check if Docker is installed
docker --version > nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker tidak terinstal. Silakan install Docker Desktop untuk Windows.
    exit /b 1
)

:: Check if Dockerfile exists
if not exist %DOCKERFILE% (
    echo [ERROR] %DOCKERFILE% tidak ditemukan.
    exit /b 1
)

:: Build information
echo [INFO] Memulai proses build Docker image di lingkungan Windows...

:: Clean up any old images
echo [INFO] Membersihkan image lama...
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG% 2>nul

:: Build the combined image
echo [INFO] Building Docker image...
echo [INFO] Menggunakan Dockerfile: %DOCKERFILE%
docker build --no-cache -t %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG% -f %DOCKERFILE% .
if %errorlevel% neq 0 (
    echo [ERROR] Gagal melakukan build Docker image
    exit /b 1
)

:: Verify the build
echo [INFO] Memverifikasi build image...
docker images | findstr %IMAGE_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] Image tidak ditemukan setelah build
    exit /b 1
)

:: Login to Docker Hub
echo [INFO] Login ke Docker Hub...
docker login -u %DOCKER_USERNAME%
if %errorlevel% neq 0 (
    echo [ERROR] Gagal login ke Docker Hub
    exit /b 1
)

:: Push image to Docker Hub
echo [INFO] Pushing image ke Docker Hub...
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%
if %errorlevel% neq 0 (
    echo [ERROR] Gagal push image ke Docker Hub
    exit /b 1
)

echo [SUCCESS] Image berhasil di-push ke Docker Hub: %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%

:: Display image information
echo [INFO] Informasi image:
docker inspect %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG% | findstr /i "Id Created Size"

endlocal