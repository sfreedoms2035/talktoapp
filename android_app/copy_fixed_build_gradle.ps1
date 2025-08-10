# PowerShell script to copy the fixed build.gradle file to the flutter_foreground_task package

$packagePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\flutter_foreground_task-3.10.0\android"
$fixedBuildGradlePath = "fixed_build.gradle"
$targetBuildGradlePath = "$packagePath\build.gradle"

# Check if the package directory exists
if (-not (Test-Path $packagePath)) {
    Write-Host "Package directory not found: $packagePath" -ForegroundColor Red
    exit 1
}

# Check if the fixed build.gradle file exists
if (-not (Test-Path $fixedBuildGradlePath)) {
    Write-Host "Fixed build.gradle file not found: $fixedBuildGradlePath" -ForegroundColor Red
    exit 1
}

# Backup the original build.gradle file
if (Test-Path $targetBuildGradlePath) {
    Copy-Item -Path $targetBuildGradlePath -Destination "$targetBuildGradlePath.bak" -Force
    Write-Host "Original build.gradle backed up to $targetBuildGradlePath.bak" -ForegroundColor Green
}

# Copy the fixed build.gradle file
Copy-Item -Path $fixedBuildGradlePath -Destination $targetBuildGradlePath -Force
Write-Host "Fixed build.gradle copied to $targetBuildGradlePath" -ForegroundColor Green

Write-Host "Done!" -ForegroundColor Green
