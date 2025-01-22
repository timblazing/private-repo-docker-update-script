#!/bin/bash

# Configuration
CONTAINER_NAME="your-container-name"
DIRECTORY_NAME="your-directory-name"
GITHUB_REPO="https://your-token@github.com/username/repository"

# Exit on any error
set -e

# Function to handle errors
handle_error() {
    echo "Error occurred in update script. Check the error message above."
    exit 1
}

# Set error handler
trap 'handle_error' ERR

echo "Starting update process..."

# Stop and remove all containers
echo "Stopping Docker containers..."
docker compose down 2>/dev/null || true
docker rm -f $(docker ps -a -q --filter name=$CONTAINER_NAME) 2>/dev/null || true

# Remove Docker images
echo "Removing Docker images..."
docker rmi -f $(docker images -q --filter reference=$CONTAINER_NAME) 2>/dev/null || true

# Store current directory
CURRENT_DIR=$(pwd)
DIR_NAME=$(basename "$CURRENT_DIR")

# Remove old directory
echo "Removing old project directory..."
if [ "$DIR_NAME" = "$DIRECTORY_NAME" ]; then
    cd ..
fi
rm -rf $DIRECTORY_NAME

# Clone repository
echo "Cloning repository..."
if ! git clone $GITHUB_REPO; then
    echo "Failed to clone repository. Please check your internet connection and GitHub token."
    exit 1
fi

# Change to project directory
cd $DIRECTORY_NAME || exit 1

# Start Docker container
echo "Starting Docker container..."
if ! docker compose up --build -d; then
    echo "Failed to start Docker container. Please check Docker logs for details."
    exit 1
fi

# Clean up unused and dangling images
echo "Cleaning up unused Docker images..."
docker image prune -f

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 5

echo "Update complete!"
