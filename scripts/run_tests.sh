#!/bin/bash

# TalkToApp Test Runner Script

echo "Running all TalkToApp tests..."

# Run Android app tests
echo "Running Android app tests..."
cd android_app
flutter test
cd ..

# Run RunPod service tests
echo "Running RunPod service tests..."
cd runpod_app
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi
python -m pytest tests/
cd ..

echo "All tests completed!"
