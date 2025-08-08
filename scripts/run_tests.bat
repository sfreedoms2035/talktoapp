@echo off

REM TalkToApp Test Runner Script for Windows

echo Running all TalkToApp tests...

REM Run Android app tests
echo Running Android app tests...
cd android_app
flutter test
cd ..

REM Run RunPod service tests
echo Running RunPod service tests...
cd runpod_app
if exist "venv" (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
)
python -m pytest tests/
cd ..

echo All tests completed!

pause
