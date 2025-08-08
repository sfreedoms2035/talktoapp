@echo off

REM TalkToApp Android Setup Script for Windows

echo Setting up TalkToApp Android environment...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter is not installed. Please install Flutter first.
    exit /b 1
)

REM Navigate to Android app directory
cd android_app

REM Get Flutter dependencies
echo Installing Flutter dependencies...
flutter pub get

REM Check if Android SDK is available
if "%ANDROID_HOME%"=="" (
    echo ANDROID_HOME is not set. Please set it to your Android SDK path.
    exit /b 1
)

echo Android environment check passed.

REM Run Flutter doctor to check for any issues
echo Running Flutter doctor...
flutter doctor

echo Android app setup completed successfully!
echo To run the app, connect an Android device or start an emulator, then run:
echo   cd android_app
echo   flutter run

pause
