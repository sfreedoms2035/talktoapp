#!/bin/bash

# TalkToApp RunPod Setup Script
# This script automates the setup process for the RunPod server

echo "=== TalkToApp RunPod Setup Script ==="
echo "Starting setup process for TalkToApp RunPod server..."

# Check if we're running on RunPod or locally
if [ -d "/workspace" ]; then
    echo "✓ Detected RunPod environment"
    RUNPOD_ENV=true
else
    echo "✓ Detected local environment"
    RUNPOD_ENV=false
fi

# Navigate to runpod_app directory
if [ ! -d "runpod_app" ]; then
    echo "Error: runpod_app directory not found."
    echo "Please run this script from the project root directory."
    exit 1
fi

cd runpod_app
echo "✓ Navigated to runpod_app directory"

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Error: Python 3 is not installed."
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "✓ Python 3 is installed"

# Check Python version
PYTHON_VERSION=$(python3 --version)
echo "✓ $PYTHON_VERSION"

# Check if pip is installed
if ! command -v pip3 &> /dev/null
then
    echo "Error: pip3 is not installed."
    echo "Please install pip3"
    exit 1
fi

echo "✓ pip3 is installed"

# Install dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "Error: Failed to install dependencies"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOF
MODEL_NAME=unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit
HOST=0.0.0.0
PORT=8000
DEBUG=False
EOF
    echo "✓ .env file created"
else
    echo "✓ .env file already exists"
fi

# Check if we're on RunPod and set up accordingly
if [ "$RUNPOD_ENV" = true ]; then
    echo "Configuring for RunPod environment..."
    
    # Check if we have GPU access
    if nvidia-smi &> /dev/null
    then
        echo "✓ NVIDIA GPU detected"
        echo "✓ CUDA drivers available"
    else
        echo "Warning: No NVIDIA GPU detected. Model will run on CPU (slower performance)."
    fi
    
    # Check available disk space
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
    echo "✓ Available disk space: $AVAILABLE_SPACE"
    
    # Check if we have enough space for the model (approximately 15GB)
    # This is a rough check - we'll check actual space during model loading
    echo "Note: Ensure you have at least 15GB of free space for the model files"
else
    echo "Configuring for local environment..."
    echo "Note: For production deployment, please follow the RunPod deployment tutorial"
fi

# Test import of key packages
echo "Testing key package imports..."
python3 -c "import torch; print('✓ PyTorch imported successfully')"
python3 -c "import transformers; print('✓ Transformers imported successfully')"
python3 -c "import fastapi; print('✓ FastAPI imported successfully')"

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Run the server with 'python3 main.py'"
echo "2. For production use, consider using a process manager like screen or tmux"
echo "3. Configure your network settings to expose port 8000"
echo ""
echo "For detailed instructions, see tutorials/runpod_deployment_tutorial.md"
