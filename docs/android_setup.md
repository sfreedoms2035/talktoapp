# Android App Setup Guide

This guide provides detailed instructions for setting up and running the TalkToApp Android client.

## Prerequisites

Before setting up the Android app, ensure you have the following installed:

1. **Flutter SDK** (version 3.0 or higher)
2. **Android Studio** or **Visual Studio Code** with Flutter extensions
3. **Android SDK** with API level 21 or higher
4. **Android device** or **emulator** with camera and microphone permissions
5. **Git** for version control

## System Requirements

### Development Environment
- Operating System: Windows 10/11, macOS 10.14+, or Linux
- RAM: 8GB minimum (16GB recommended)
- Disk Space: 4GB free space for Flutter and Android SDK
- Internet connection for downloading dependencies

### Target Device
- Android 5.0 (API level 21) or higher
- Rear camera
- Microphone
- Internet connectivity

## Installation Steps

### 1. Install Flutter

If you haven't already installed Flutter, follow these steps:

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract the downloaded file to a desired location
3. Add Flutter to your system PATH:
   ```bash
   export PATH="$PATH:`pwd`/flutter/bin"
   ```
4. Verify installation:
   ```bash
   flutter --version
   ```

### 2. Set up Android Development Environment

1. Install Android Studio from [developer.android.com](https://developer.android.com/studio)
2. During installation, ensure the following components are selected:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
3. Set up Android SDK paths:
   ```bash
   export ANDROID_HOME=/path/to/android/sdk
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

### 3. Clone the Repository

```bash
git clone https://github.com/your-username/talktoapp.git
cd talktoapp/android_app
```

### 4. Install Dependencies

Navigate to the Android app directory and install Flutter dependencies:

```bash
cd android_app
flutter pub get
```

### 5. Configure Android Device

#### Physical Device
1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to Settings > Developer Options
   - Enable "USB Debugging"
3. Connect your device to your computer via USB
4. Accept the RSA key prompt on your device

#### Emulator
1. Open Android Studio
2. Go to Tools > AVD Manager
3. Create a new Virtual Device:
   - Select a device definition (e.g., Pixel 4)
   - Select a system image (API level 21 or higher)
   - Complete the AVD setup
4. Start the emulator

### 6. Verify Setup

Run Flutter doctor to check for any issues:

```bash
flutter doctor
```

This command will show any missing dependencies or configuration issues.

## Project Structure

The Android app follows a standard Flutter project structure:

```
android_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── app_state.dart
│   ├── screens/
│   │   └── home_screen.dart
│   ├── services/
│   │   ├── camera_service.dart
│   │   ├── communication_service.dart
│   │   ├── tts_service.dart
│   │   └── voice_service.dart
│   └── widgets/
│       ├── connection_status.dart
│       ├── status_indicator.dart
│       └── trigger_display.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

## Configuration

### RunPod Server Configuration

The Android app needs to know the IP address of your RunPod server. Update the server URL in `lib/services/communication_service.dart`:

```dart
static const String _baseUrl = 'http://YOUR_RUNPOD_IP:8000';
```

Replace `YOUR_RUNPOD_IP` with the actual IP address of your RunPod server.

### Permissions

The app requires the following permissions, which are already configured in `android/app/src/main/AndroidManifest.xml`:

- `android.permission.CAMERA`
- `android.permission.RECORD_AUDIO`
- `android.permission.INTERNET`

## Running the App

### Development Mode

To run the app in development mode:

```bash
flutter run
```

This will automatically detect connected devices or running emulators and deploy the app.

### Release Mode

To build a release version of the app:

```bash
flutter build apk --release
```

The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## Testing

### Running Unit Tests

Execute the widget tests:

```bash
flutter test
```

### Manual Testing

1. Launch the app on your device/emulator
2. Grant camera and microphone permissions when prompted
3. Say "Hey monitor" to trigger the app
4. Verify that the app captures an image
5. Speak a query after the image is captured
6. Verify that the response is played back as speech

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues
If `flutter doctor` shows issues:
- Install missing Android licenses: `flutter doctor --android-licenses`
- Install missing SDK components through Android Studio

#### 2. Device Not Detected
- Ensure USB debugging is enabled
- Try different USB cables
- Check device driver installation on Windows

#### 3. Camera Permission Denied
- Manually grant camera permission in device settings
- Uninstall and reinstall the app

#### 4. Network Connection Issues
- Verify RunPod server is running
- Check firewall settings
- Ensure device and server are on the same network

### Debugging

To view app logs:

```bash
flutter logs
```

To run with verbose output:

```bash
flutter run -v
```

## Performance Optimization

### Build Optimization
- Use `flutter build apk --split-per-abi` to generate separate APKs for different architectures
- Enable code shrinking with ProGuard for release builds

### Runtime Optimization
- Monitor memory usage with Android Studio's profiler
- Optimize image capture resolution if needed
- Minimize widget rebuilds in the UI

## Deployment

### Google Play Store
To publish on Google Play Store:
1. Create a signed APK or App Bundle
2. Create a Google Play Developer account
3. Follow Google's publishing guidelines
4. Upload your app and complete the store listing

### Enterprise Deployment
For enterprise use:
- Distribute APK directly to users
- Use Mobile Device Management (MDM) solutions
- Consider Firebase App Distribution for beta testing

## Updating Dependencies

To update Flutter dependencies:

```bash
flutter pub upgrade
```

To update to a specific version:

```bash
flutter pub upgrade package_name
```

## Contributing

To contribute to the Android app:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests to ensure nothing is broken
5. Submit a pull request

## Support

For issues or questions:
1. Check the project documentation
2. Search existing GitHub issues
3. Create a new issue with detailed information about the problem
