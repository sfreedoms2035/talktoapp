@echo off
REM TalkToApp Android Setup Script (Windows)
REM This script automates the setup process for the Android client

echo === TalkToApp Android Setup Script ===
echo Starting setup process for TalkToApp Android client...

REM Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed.
    echo Please install Flutter SDK from https://flutter.dev/docs/get-started/install
    exit /b 1
)

echo ✓ Flutter is installed

REM Check Flutter version
for /f "delims=" %%a in ('flutter --version ^| findstr /n "^" ^| findstr "^1:"') do set FLUTTER_VERSION=%%a
echo ✓ Flutter version: %FLUTTER_VERSION%

REM Navigate to android_app directory
if not exist "android_app" (
    echo Error: android_app directory not found.
    echo Please run this script from the project root directory.
    exit /b 1
)

cd android_app
echo ✓ Navigated to android_app directory

REM Install dependencies
echo Installing Flutter dependencies...
flutter pub get

if %errorlevel% equ 0 (
    echo ✓ Dependencies installed successfully
) else (
    echo Error: Failed to install dependencies
    exit /b 1
)

REM Run Flutter doctor to check for issues
echo Running Flutter doctor...
flutter doctor

echo ✓ Detected Windows environment

REM Check for connected devices
echo Checking for connected devices...
flutter devices

echo.
echo === Setup Complete ===
echo Next steps:
echo 1. Configure your RunPod server IP in lib/services/communication_service.dart
echo 2. Connect an Android device or start an emulator
echo 3. Run 'flutter run' to start the application
echo.
echo For detailed instructions, see tutorials/android_installation_guide.md
