@echo off
REM TalkToApp Test Runner Script (Windows)
REM This script runs tests for both the Android app and RunPod server

echo === TalkToApp Test Runner ===
echo Running tests for TalkToApp components...

REM Function to run Android tests
:run_android_tests
echo.
echo === Running Android App Tests ===

REM Check if we're in the correct directory
if not exist "android_app" (
    echo Error: android_app directory not found.
    echo Please run this script from the project root directory.
    exit /b 1
)

cd android_app

REM Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed.
    echo Please install Flutter SDK to run Android tests.
    cd ..
    exit /b 1
)

echo ✓ Flutter is installed

REM Run Flutter tests
echo Running Flutter unit tests...
flutter test

if %errorlevel% equ 0 (
    echo ✓ Android app tests passed
) else (
    echo ✗ Android app tests failed
    cd ..
    exit /b 1
)

cd ..
goto :eof

REM Function to run RunPod tests
:run_runpod_tests
echo.
echo === Running RunPod Server Tests ===

REM Check if we're in the correct directory
if not exist "runpod_app" (
    echo Error: runpod_app directory not found.
    echo Please run this script from the project root directory.
    exit /b 1
)

cd runpod_app

REM Check if Python is installed
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed.
    echo Please install Python 3.8 or higher to run RunPod tests.
    cd ..
    exit /b 1
)

echo ✓ Python is installed

REM Run Python tests
echo Running Python unit tests...
python -m unittest discover tests/

if %errorlevel% equ 0 (
    echo ✓ RunPod server tests passed
) else (
    echo ✗ RunPod server tests failed
    cd ..
    exit /b 1
)

cd ..
goto :eof

REM Function to run integration tests
:run_integration_tests
echo.
echo === Running Integration Tests ===

REM These are conceptual tests that would check the interaction between components
echo Checking project structure...

REM Check if required directories exist
if not exist "android_app" (
    echo ✗ android_app directory missing
    exit /b 1
)

if not exist "runpod_app" (
    echo ✗ runpod_app directory missing
    exit /b 1
)

if not exist "docs" (
    echo ✗ docs directory missing
    exit /b 1
)

if not exist "tutorials" (
    echo ✗ tutorials directory missing
    exit /b 1
)

if not exist "scripts" (
    echo ✗ scripts directory missing
    exit /b 1
)

echo ✓ All required directories present

REM Check if required files exist
if not exist "android_app\pubspec.yaml" (
    echo ✗ android_app\pubspec.yaml missing
    exit /b 1
)

if not exist "runpod_app\requirements.txt" (
    echo ✗ runpod_app\requirements.txt missing
    exit /b 1
)

if not exist "README.md" (
    echo ✗ README.md missing
    exit /b 1
)

echo ✓ All required files present

echo ✓ Integration tests passed
goto :eof

REM Main execution
if "%1"=="" (
    REM Run all tests by default
    call :run_android_tests
    call :run_runpod_tests
    call :run_integration_tests
) else if "%1"=="android" (
    call :run_android_tests
) else if "%1"=="runpod" (
    call :run_runpod_tests
) else if "%1"=="integration" (
    call :run_integration_tests
) else (
    echo Usage: %0 [android^|runpod^|integration]
    echo   android      Run Android app tests only
    echo   runpod       Run RunPod server tests only
    echo   integration  Run integration tests only
    echo   (no args)    Run all tests
    exit /b 1
)

echo.
echo === Test Execution Complete ===
echo Check the output above for test results.
echo For detailed test information, see the respective test files in each component.
