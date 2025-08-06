# Android App Setup Guide

This guide provides detailed instructions for setting up and running the TalkToApp Android client.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0 or higher)
2. **Android Studio** (latest stable version)
3. **Android SDK** with API level 21 or higher
4. **Git** for version control

## Installation Steps

### 1. Install Flutter

If you haven't installed Flutter yet:

1. Download Flutter SDK from https://flutter.dev/docs/get-started/install
2. Extract the downloaded file to a preferred location
3. Add Flutter to your system PATH:
   ```bash
   export PATH="$PATH:`pwd`/flutter/bin"
   ```
4. Verify installation:
   ```bash
   flutter doctor
   ```

### 2. Install Android Studio

1. Download Android Studio from https://developer.android.com/studio
2. Follow the installation wizard
3. During installation, ensure Android SDK and emulator components are selected

### 3. Configure Android Device

You can use either a physical Android device or an emulator:

#### Physical Device
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect device via USB
4. Trust the computer on your device

#### Android Emulator
1. Open Android Studio
2. Go to Tools > AVD Manager
3. Create a new virtual device with API level 21 or higher
4. Start the emulator

### 4. Clone the Repository

```bash
git clone <repository-url>
cd talktoapp/android_app
```

### 5. Install Dependencies

```bash
flutter pub get
```

This command installs all the required Flutter packages specified in `pubspec.yaml`.

## Configuration

### RunPod Server Configuration

Before running the app, you need to configure the RunPod server URL:

1. Open `lib/services/communication_service.dart`
2. Update the `_baseUrl` constant with your RunPod server IP:
   ```dart
   static const String _baseUrl = 'http://YOUR_RUNPOD_IP:8000';
   ```
   
Replace `YOUR_RUNPOD_IP` with the actual IP address of your RunPod instance.

### Permissions

The app requires several permissions that are automatically declared in the AndroidManifest.xml file:

1. **Camera**: For capturing images
2. **Microphone**: For voice recognition
3. **Internet**: For communicating with RunPod service

These permissions are requested at runtime when needed.

## Running the Application

### Using Command Line

1. Connect your Android device or start an emulator
2. Check available devices:
   ```bash
   flutter devices
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Using Android Studio

1. Open the `android_app` directory in Android Studio
2. Select your target device from the device dropdown
3. Click the "Run" button or press Shift+F10

## Building APK

To build a release APK:

```bash
flutter build apk --release
```

The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`

## Debugging

### Common Issues and Solutions

#### 1. Flutter Not Found
- Ensure Flutter is added to your system PATH
- Restart your terminal/command prompt

#### 2. No Connected Devices
- Check USB connection for physical devices
- Ensure USB debugging is enabled
- Start an emulator if using virtual device

#### 3. Permission Denied
- Grant required permissions when prompted
- Check app settings if permissions were denied

#### 4. Connection Failed
- Verify RunPod server is running
- Check network connectivity
- Confirm server IP address is correct

### Viewing Logs

#### Flutter Logs
```bash
flutter logs
```

#### Android Studio Logcat
1. Open Android Studio
2. Go to View > Tool Windows > Logcat
3. Filter by your app's package name

## Testing

### Running Unit Tests
```bash
flutter test
```

### Manual Testing Checklist
1. Grant all required permissions when prompted
2. Test voice trigger detection
3. Verify camera functionality
4. Check connection to RunPod server
5. Test text-to-speech functionality
6. Verify status indicators update correctly

## Performance Optimization

### Image Compression
Images are automatically compressed before transmission to reduce bandwidth usage and improve response times.

### Background Processing
Heavy operations like image processing and network requests run in background isolates to prevent UI blocking.

### Connection Management
HTTP connections are reused through connection pooling for better performance.

## Troubleshooting

### Android Studio Issues
- **Gradle sync failed**: Try "File > Sync Project with Gradle Files"
- **SDK not found**: Check Flutter SDK path in Android Studio settings

### Emulator Issues
- **Slow performance**: Enable hardware acceleration in BIOS
- **Emulator won't start**: Check system requirements and available RAM

### Network Issues
- **Connection timeout**: Verify server IP and port
- **Firewall blocking**: Check firewall settings on both client and server

## Updating Dependencies

To update Flutter dependencies:

```bash
flutter pub upgrade
```

Always test the app after updating dependencies to ensure compatibility.

## Contributing

### Code Style
- Follow Flutter's official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Testing
- Add unit tests for new functionality
- Test on multiple Android versions if possible
- Verify performance impact of changes

### Pull Requests
- Create feature branches for new functionality
- Include detailed descriptions of changes
- Ensure all tests pass before submitting
