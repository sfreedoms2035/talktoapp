#!/bin/bash

# TalkToApp Test Runner Script
# This script runs tests for both the Android app and RunPod server

echo "=== TalkToApp Test Runner ==="
echo "Running tests for TalkToApp components..."

# Function to run Android tests
run_android_tests() {
    echo ""
    echo "=== Running Android App Tests ==="
    
    # Check if we're in the correct directory
    if [ ! -d "android_app" ]; then
        echo "Error: android_app directory not found."
        echo "Please run this script from the project root directory."
        return 1
    fi
    
    cd android_app
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null
    then
        echo "Error: Flutter is not installed."
        echo "Please install Flutter SDK to run Android tests."
        cd ..
        return 1
    fi
    
    echo "✓ Flutter is installed"
    
    # Run Flutter tests
    echo "Running Flutter unit tests..."
    flutter test
    
    if [ $? -eq 0 ]; then
        echo "✓ Android app tests passed"
    else
        echo "✗ Android app tests failed"
        cd ..
        return 1
    fi
    
    cd ..
}

# Function to run RunPod tests
run_runpod_tests() {
    echo ""
    echo "=== Running RunPod Server Tests ==="
    
    # Check if we're in the correct directory
    if [ ! -d "runpod_app" ]; then
        echo "Error: runpod_app directory not found."
        echo "Please run this script from the project root directory."
        return 1
    fi
    
    cd runpod_app
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null
    then
        echo "Error: Python 3 is not installed."
        echo "Please install Python 3.8 or higher to run RunPod tests."
        cd ..
        return 1
    fi
    
    echo "✓ Python 3 is installed"
    
    # Check if required packages are installed by trying to import them
    echo "Checking for required Python packages..."
    python3 -c "import unittest" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Python unittest module not available."
        cd ..
        return 1
    fi
    
    # Run Python tests
    echo "Running Python unit tests..."
    python3 -m unittest discover tests/
    
    if [ $? -eq 0 ]; then
        echo "✓ RunPod server tests passed"
    else
        echo "✗ RunPod server tests failed"
        cd ..
        return 1
    fi
    
    cd ..
}

# Function to run integration tests
run_integration_tests() {
    echo ""
    echo "=== Running Integration Tests ==="
    
    # These are conceptual tests that would check the interaction between components
    echo "Checking project structure..."
    
    # Check if required directories exist
    if [ ! -d "android_app" ]; then
        echo "✗ android_app directory missing"
        return 1
    fi
    
    if [ ! -d "runpod_app" ]; then
        echo "✗ runpod_app directory missing"
        return 1
    fi
    
    if [ ! -d "docs" ]; then
        echo "✗ docs directory missing"
        return 1
    fi
    
    if [ ! -d "tutorials" ]; then
        echo "✗ tutorials directory missing"
        return 1
    fi
    
    if [ ! -d "scripts" ]; then
        echo "✗ scripts directory missing"
        return 1
    fi
    
    echo "✓ All required directories present"
    
    # Check if required files exist
    if [ ! -f "android_app/pubspec.yaml" ]; then
        echo "✗ android_app/pubspec.yaml missing"
        return 1
    fi
    
    if [ ! -f "runpod_app/requirements.txt" ]; then
        echo "✗ runpod_app/requirements.txt missing"
        return 1
    fi
    
    if [ ! -f "README.md" ]; then
        echo "✗ README.md missing"
        return 1
    fi
    
    echo "✓ All required files present"
    
    echo "✓ Integration tests passed"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # Run all tests by default
    run_android_tests
    run_runpod_tests
    run_integration_tests
elif [ "$1" == "android" ]; then
    run_android_tests
elif [ "$1" == "runpod" ]; then
    run_runpod_tests
elif [ "$1" == "integration" ]; then
    run_integration_tests
else
    echo "Usage: $0 [android|runpod|integration]"
    echo "  android      Run Android app tests only"
    echo "  runpod       Run RunPod server tests only"
    echo "  integration  Run integration tests only"
    echo "  (no args)    Run all tests"
    exit 1
fi

echo ""
echo "=== Test Execution Complete ==="
echo "Check the output above for test results."
echo "For detailed test information, see the respective test files in each component."
