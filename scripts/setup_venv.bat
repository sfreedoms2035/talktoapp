@echo off
REM TalkToApp Virtual Environment Setup Script (Windows)
REM This script sets up a Python virtual environment for the RunPod server

echo === TalkToApp Virtual Environment Setup ===
echo Setting up Python virtual environment...

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
echo ✓ %PYTHON_VERSION% is installed

REM Create virtual environment
echo Creating virtual environment...
python -m venv talktoapp_venv

if %errorlevel% equ 0 (
    echo ✓ Virtual environment created successfully
) else (
    echo Error: Failed to create virtual environment
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call talktoapp_venv\Scripts\activate

if %errorlevel% equ 0 (
    echo ✓ Virtual environment activated
) else (
    echo Error: Failed to activate virtual environment
    exit /b 1
)

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

if %errorlevel% equ 0 (
    echo ✓ pip upgraded successfully
) else (
    echo Warning: Failed to upgrade pip
)

REM Install requirements
if exist "runpod_app\requirements.txt" (
    echo Installing RunPod server requirements...
    pip install -r runpod_app\requirements.txt
    
    if %errorlevel% equ 0 (
        echo ✓ RunPod server requirements installed
    ) else (
        echo Error: Failed to install RunPod server requirements
        exit /b 1
    )
) else (
    echo Warning: runpod_app\requirements.txt not found
)

REM Deactivate virtual environment
echo Deactivating virtual environment...
deactivate

echo.
echo === Virtual Environment Setup Complete ===
echo To activate the virtual environment, run:
echo   talktoapp_venv\Scripts\activate
echo.
echo To deactivate the virtual environment, run:
echo   deactivate
echo.
echo Virtual environment location: talktoapp_venv\
