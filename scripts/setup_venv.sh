#!/bin/bash

# TalkToApp Virtual Environment Setup Script

echo "Setting up Python virtual environment for RunPod service..."

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Navigate to RunPod app directory
cd runpod_app

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

echo "Virtual environment setup completed successfully!"
echo "To activate the virtual environment, run:"
echo "  cd runpod_app"
echo "  source venv/bin/activate"
