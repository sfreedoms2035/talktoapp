# TalkToApp Scripts

This directory contains scripts to help with setting up, testing, and managing the TalkToApp project.

## Script Overview

### Setup Scripts
- `setup_android.sh` / `setup_android.bat` - Setup script for the Android app
- `setup_runpod.sh` / `setup_runpod.bat` - Setup script for the RunPod server
- `setup_venv.sh` / `setup_venv.bat` - Virtual environment setup for Python dependencies

### Test Scripts
- `run_tests.sh` / `run_tests.bat` - Run tests for all components or specific ones

## Usage

### Setting up the Android App

**On Linux/Mac:**
```bash
./scripts/setup_android.sh
```

**On Windows:**
```cmd
scripts\setup_android.bat
```

### Setting up the RunPod Server

**On Linux/Mac:**
```bash
./scripts/setup_runpod.sh
```

**On Windows:**
```cmd
scripts\setup_runpod.bat
```

### Setting up Virtual Environment

**On Linux/Mac:**
```bash
./scripts/setup_venv.sh
```

**On Windows:**
```cmd
scripts\setup_venv.bat
```

### Running Tests

**On Linux/Mac:**
```bash
# Run all tests
./scripts/run_tests.sh

# Run specific tests
./scripts/run_tests.sh android
./scripts/run_tests.sh runpod
./scripts/run_tests.sh integration
```

**On Windows:**
```cmd
REM Run all tests
scripts\run_tests.bat

REM Run specific tests
scripts\run_tests.bat android
scripts\run_tests.bat runpod
scripts\run_tests.bat integration
```

## Prerequisites

Before running these scripts, ensure you have:

1. **For Android App**:
   - Flutter SDK 3.0 or higher
   - Android Studio (for Android development)
   - Android SDK with API level 21 or higher

2. **For RunPod Server**:
   - Python 3.8 or higher
   - pip package manager
   - Git for version control

## Script Details

### setup_android.sh / setup_android.bat

This script:
1. Checks if Flutter is installed
2. Verifies Flutter version compatibility
3. Installs Flutter dependencies
4. Runs Flutter doctor to check for issues
5. Checks for connected devices

### setup_runpod.sh / setup_runpod.bat

This script:
1. Checks if Python is installed
2. Verifies Python version compatibility
3. Installs Python dependencies from requirements.txt
4. Creates a .env file with default configuration
5. Tests key package imports

### setup_venv.sh / setup_venv.bat

This script:
1. Creates a Python virtual environment
2. Activates the virtual environment
3. Upgrades pip to the latest version
4. Installs RunPod server requirements
5. Deactivates the virtual environment

### run_tests.sh / run_tests.bat

This script:
1. Runs Android app tests using Flutter test
2. Runs RunPod server tests using Python unittest
3. Runs integration tests to verify project structure
4. Supports running specific test suites

## Troubleshooting

### Common Issues

1. **Flutter not found**: Ensure Flutter is installed and added to your PATH
2. **Python not found**: Ensure Python 3.8+ is installed and accessible
3. **Permission denied**: On Linux/Mac, ensure scripts are executable (chmod +x)
4. **Dependencies not installing**: Check internet connection and package managers

### Getting Help

If you encounter issues with these scripts:
1. Check the console output for error messages
2. Verify all prerequisites are installed
3. Refer to the detailed setup guides in the tutorials directory
4. Check the troubleshooting guide in the docs directory

## Contributing

To contribute new scripts or modify existing ones:
1. Follow the existing naming conventions
2. Provide both .sh and .bat versions for cross-platform compatibility
3. Include clear error handling and user feedback
4. Update this README with any new scripts or changes to existing ones
