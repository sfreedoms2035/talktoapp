#!/bin/bash

# TalkToApp Android Setup Script
# This script automates the setup process for the Android client

echo "=== TalkToApp Android Setup Script ==="
echo "Starting setup process for TalkToApp Android client..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "Error: Flutter is not installed."
    echo "Please install Flutter SDK from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ Flutter is installed"

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✓ Flutter version: $FLUTTER_VERSION"

# Navigate to android_app directory
if [ ! -d "android_app" ]; then
    echo "Error: android_app directory not found."
    echo "Please run this script from the project root directory."
    exit 1
fi

cd android_app
echo "✓ Navigated to android_app directory"

# Install dependencies
echo "Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "Error: Failed to install dependencies"
    exit 1
fi

# Run Flutter doctor to check for issues
echo "Running Flutter doctor..."
flutter doctor

# Check if we're on Windows (Git Bash) or Unix
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "✓ Detected Windows environment"
    echo "Note: On Windows, you may need to run 'flutter pub get' in PowerShell or Command Prompt if this fails"
else
    # Unix/Linux/Mac
    echo "✓ Detected Unix-like environment"
fi

# Check for connected devices
echo "Checking for connected devices..."
flutter devices

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Configure your RunPod server IP in lib/services/communication_service.dart"
echo "2. Connect an Android device or start an emulator"
echo "3. Run 'flutter run' to start the application"
echo ""
echo "For detailed instructions, see tutorials/android_installation_guide.md"
