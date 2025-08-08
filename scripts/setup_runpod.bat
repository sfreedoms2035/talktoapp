@echo off

REM TalkToApp RunPod Service Setup Script for Windows

echo Setting up TalkToApp RunPod service environment...

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

REM Check if HF_TOKEN is set
if "%HF_TOKEN%"=="" (
    echo Warning: HF_TOKEN environment variable is not set.
    echo You need to set your Hugging Face token to access the Qwen model.
    echo set HF_TOKEN=your_hugging_face_token
)

echo RunPod service setup completed successfully!
echo To run the service, execute:
echo   cd runpod_app
echo   call venv\Scripts\activate.bat
echo   set HF_TOKEN=your_hugging_face_token
echo   python main.py

pause
