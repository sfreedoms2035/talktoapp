@echo off
REM TalkToApp RunPod Setup Script (Windows)
REM This script automates the setup process for the RunPod server

echo === TalkToApp RunPod Setup Script ===
echo Starting setup process for TalkToApp RunPod server...

REM Check if we're running on RunPod or locally
if exist "C:\workspace" (
    echo ✓ Detected RunPod environment
    set RUNPOD_ENV=true
) else (
    echo ✓ Detected local environment
    set RUNPOD_ENV=false
)

REM Navigate to runpod_app directory
if not exist "runpod_app" (
    echo Error: runpod_app directory not found.
    echo Please run this script from the project root directory.
    exit /b 1
)

cd runpod_app
echo ✓ Navigated to runpod_app directory

REM Check if Python is installed
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed.
    echo Please install Python 3.8 or higher
    exit /b 1
)

echo ✓ Python is installed

REM Check Python version
for /f "delims=" %%a in ('python --version') do set PYTHON_VERSION=%%a
echo ✓ %PYTHON_VERSION%

REM Check if pip is installed
where pip >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: pip is not installed.
    echo Please install pip
    exit /b 1
)

echo ✓ pip is installed

REM Install dependencies
echo Installing Python dependencies...
pip install -r requirements.txt

if %errorlevel% equ 0 (
    echo ✓ Dependencies installed successfully
) else (
    echo Error: Failed to install dependencies
    exit /b 1
)

REM Create .env file if it doesn't exist
if not exist ".env" (
    echo Creating .env file...
    echo MODEL_NAME=unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit > .env
    echo HOST=0.0.0.0 >> .env
    echo PORT=8000 >> .env
    echo DEBUG=False >> .env
    echo ✓ .env file created
) else (
    echo ✓ .env file already exists
)

REM Check if we're on RunPod and set up accordingly
if "%RUNPOD_ENV%"=="true" (
    echo Configuring for RunPod environment...
    
    REM Check if we have GPU access
    where nvidia-smi >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ NVIDIA GPU detected
        echo ✓ CUDA drivers available
    ) else (
        echo Warning: No NVIDIA GPU detected. Model will run on CPU (slower performance).
    )
    
    REM Check available disk space
    for /f "tokens=*" %%a in ('dir C:\ /-C ^| findstr "bytes free"') do set DISK_SPACE=%%a
    echo ✓ Available disk space: %DISK_SPACE%
    
    REM Check if we have enough space for the model (approximately 15GB)
    echo Note: Ensure you have at least 15GB of free space for the model files
) else (
    echo Configuring for local environment...
    echo Note: For production deployment, please follow the RunPod deployment tutorial
)

REM Test import of key packages
echo Testing key package imports...
python -c "import torch; print('✓ PyTorch imported successfully')"
python -c "import transformers; print('✓ Transformers imported successfully')"
python -c "import fastapi; print('✓ FastAPI imported successfully')"

echo.
echo === Setup Complete ===
echo Next steps:
echo 1. Run the server with 'python main.py'
echo 2. For production use, consider using a process manager
echo 3. Configure your network settings to expose port 8000
echo.
echo For detailed instructions, see tutorials/runpod_deployment_tutorial.md
