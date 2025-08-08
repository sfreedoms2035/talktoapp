@echo off

REM TalkToApp Virtual Environment Setup Script for Windows

echo Setting up Python virtual environment for RunPod service...

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed. Please install Python first.
    exit /b 1
)

REM Navigate to RunPod app directory
cd runpod_app

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo Installing Python dependencies...
pip install -r requirements.txt

echo Virtual environment setup completed successfully!
echo To activate the virtual environment, run:
echo   cd runpod_app
echo   call venv\Scripts\activate.bat

pause
