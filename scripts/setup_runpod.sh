#!/bin/bash

# TalkToApp RunPod Service Setup Script

echo "Setting up TalkToApp RunPod service environment..."

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

# Check if HF_TOKEN is set
if [ -z "$HF_TOKEN" ]; then
    echo "Warning: HF_TOKEN environment variable is not set."
    echo "You need to set your Hugging Face token to access the Qwen model."
    echo "export HF_TOKEN=your_hugging_face_token"
fi

echo "RunPod service setup completed successfully!"
echo "To run the service, execute:"
echo "  cd runpod_app"
echo "  source venv/bin/activate  # On Windows: venv\Scripts\activate"
echo "  export HF_TOKEN=your_hugging_face_token  # Set your HF token"
echo "  python main.py"
