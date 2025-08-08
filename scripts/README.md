# TalkToApp Scripts

This directory contains automated scripts to help set up and run the TalkToApp project.

## Setup Scripts

### Android App Setup
- `setup_android.sh` - Setup script for Unix/Linux/macOS
- `setup_android.bat` - Setup script for Windows

These scripts will:
- Check if Flutter is installed
- Install Flutter dependencies
- Verify Android SDK installation
- Run Flutter doctor to check for issues

### RunPod Service Setup
- `setup_runpod.sh` - Setup script for Unix/Linux/macOS
- `setup_runpod.bat` - Setup script for Windows

These scripts will:
- Check if Python is installed
- Create a Python virtual environment
- Install required Python packages
- Verify Hugging Face token setup

### Virtual Environment Setup
- `setup_venv.sh` - Virtual environment setup for Unix/Linux/macOS
- `setup_venv.bat` - Virtual environment setup for Windows

These scripts will:
- Create a Python virtual environment for the RunPod service
- Install all required dependencies

## Test Scripts

### Running All Tests
- `run_tests.sh` - Run all tests for Unix/Linux/macOS
- `run_tests.bat` - Run all tests for Windows

These scripts will:
- Run Flutter widget tests for the Android app
- Run Python unit tests for the RunPod service

## Usage

### Setting up the Android App
```bash
# Unix/Linux/macOS
./setup_android.sh

# Windows
setup_android.bat
```

### Setting up the RunPod Service
```bash
# Unix/Linux/macOS
./setup_runpod.sh

# Windows
setup_runpod.bat
```

### Running Tests
```bash
# Unix/Linux/macOS
./run_tests.sh

# Windows
run_tests.bat
```

## Prerequisites

Before running these scripts, ensure you have:

1. **For Android App:**
   - Flutter SDK installed
   - Android SDK installed
   - ANDROID_HOME environment variable set

2. **For RunPod Service:**
   - Python 3.8 or higher installed
   - Hugging Face account and token (for accessing the Qwen model)

## Troubleshooting

If you encounter issues with the scripts:

1. Check that all prerequisites are installed
2. Ensure you have execute permissions on the shell scripts:
   ```bash
   chmod +x *.sh
   ```
3. For Windows users, ensure you're running the batch files with appropriate permissions
