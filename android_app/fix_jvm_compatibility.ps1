# PowerShell script to fix JVM target compatibility issue in flutter_foreground_task plugin

$packagePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\flutter_foreground_task-3.10.0\android"
$buildGradlePath = "$packagePath\build.gradle"

# Check if the package directory exists
if (-not (Test-Path $packagePath)) {
    Write-Host "Package directory not found: $packagePath" -ForegroundColor Red
    exit 1
}

# Check if the build.gradle file exists
if (-not (Test-Path $buildGradlePath)) {
    Write-Host "build.gradle file not found: $buildGradlePath" -ForegroundColor Red
    exit 1
}

# Backup the original build.gradle file
Copy-Item -Path $buildGradlePath -Destination "$buildGradlePath.bak" -Force
Write-Host "Original build.gradle backed up to $buildGradlePath.bak" -ForegroundColor Green

# Read the original build.gradle file
$content = Get-Content -Path $buildGradlePath -Raw

# Add compileOptions and kotlinOptions blocks to set Java compatibility to 11
$updatedContent = $content -replace "android {", @"
android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }
"@

# Write the updated content back to the build.gradle file
Set-Content -Path $buildGradlePath -Value $updatedContent

Write-Host "Updated build.gradle with Java 11 compatibility settings" -ForegroundColor Green
Write-Host "Done!" -ForegroundColor Green
