#!/bin/bash

# TalkToApp Virtual Environment Setup Script
# This script sets up a Python virtual environment for the RunPod server

echo "=== TalkToApp Virtual Environment Setup ==="
echo "Setting up Python virtual environment..."

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Error: Python 3 is not installed."
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "✓ Python 3 is installed"

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f1)
MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f2)

if [ $MAJOR_VERSION -lt 3 ] || [ $MAJOR_VERSION -eq 3 -a $MINOR_VERSION -lt 8 ]
then
    echo "Error: Python 3.8 or higher is required. Current version: $PYTHON_VERSION"
    exit 1
fi

echo "✓ Python version $PYTHON_VERSION is compatible"

# Check if venv module is available
python3 -c "import venv" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Error: venv module is not available."
    echo "Please install python3-venv package"
    exit 1
fi

echo "✓ venv module is available"

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv talktoapp_venv

if [ $? -eq 0 ]; then
    echo "✓ Virtual environment created successfully"
else
    echo "Error: Failed to create virtual environment"
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source talktoapp_venv/bin/activate

if [ $? -eq 0 ]; then
    echo "✓ Virtual environment activated"
else
    echo "Error: Failed to activate virtual environment"
    exit 1
fi

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

if [ $? -eq 0 ]; then
    echo "✓ pip upgraded successfully"
else
    echo "Warning: Failed to upgrade pip"
fi

# Install requirements
if [ -f "runpod_app/requirements.txt" ]; then
    echo "Installing RunPod server requirements..."
    pip install -r runpod_app/requirements.txt
    
    if [ $? -eq 0 ]; then
        echo "✓ RunPod server requirements installed"
    else
        echo "Error: Failed to install RunPod server requirements"
        exit 1
    fi
else
    echo "Warning: runpod_app/requirements.txt not found"
fi

# Deactivate virtual environment
echo "Deactivating virtual environment..."
deactivate

echo ""
echo "=== Virtual Environment Setup Complete ==="
echo "To activate the virtual environment, run:"
echo "  source talktoapp_venv/bin/activate  (Linux/Mac)"
echo "  talktoapp_venv\Scripts\activate     (Windows)"
echo ""
echo "To deactivate the virtual environment, run:"
echo "  deactivate"
echo ""
echo "Virtual environment location: talktoapp_venv/"
