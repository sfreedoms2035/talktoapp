#!/bin/bash

# TalkToApp Android Setup Script

echo "Setting up TalkToApp Android environment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Navigate to Android app directory
cd android_app

# Get Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME is not set. Please set it to your Android SDK path."
    exit 1
fi

echo "Android environment check passed."

# Run Flutter doctor to check for any issues
echo "Running Flutter doctor..."
flutter doctor

echo "Android app setup completed successfully!"
echo "To run the app, connect an Android device or start an emulator, then run:"
echo "  cd android_app"
echo "  flutter run"
