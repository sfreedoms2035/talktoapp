# Android Installation Guide

This tutorial provides step-by-step instructions for installing and setting up the TalkToApp Android client.

## Prerequisites

Before you begin, ensure you have:

1. An Android device running Android 5.0 (API level 21) or higher
2. A computer with Flutter SDK installed
3. USB cable for connecting your Android device (if using a physical device)
4. RunPod server instance running and accessible

## Step 1: Install Flutter SDK

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

## Step 2: Install Android Studio

1. Download Android Studio from https://developer.android.com/studio
2. Follow the installation wizard
3. During installation, ensure Android SDK and emulator components are selected

## Step 3: Clone the Repository

Open a terminal and run:

```bash
git clone <repository-url>
cd talktoapp/android_app
```

## Step 4: Install Dependencies

In the `android_app` directory, run:

```bash
flutter pub get
```

This command installs all the required Flutter packages specified in `pubspec.yaml`.

## Step 5: Configure RunPod Server

Before running the app, you need to configure the RunPod server URL:

1. Open `lib/services/communication_service.dart` in your code editor
2. Update the `_baseUrl` constant with your RunPod server IP:
   ```dart
   static const String _baseUrl = 'http://YOUR_RUNPOD_IP:8000';
   ```
   
Replace `YOUR_RUNPOD_IP` with the actual IP address of your RunPod instance.

## Step 6: Set Up Android Device

You can use either a physical Android device or an emulator:

### Option A: Physical Device

1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Developer Options will be enabled

2. Enable USB Debugging:
   - Go to Settings > Developer Options
   - Enable "USB Debugging"

3. Connect device via USB:
   - Connect your Android device to your computer with a USB cable
   - Trust the computer on your device when prompted

### Option B: Android Emulator

1. Open Android Studio
2. Go to Tools > AVD Manager
3. Click "Create Virtual Device"
4. Select a device definition and click "Next"
5. Select a system image with API level 21 or higher
6. Click "Next" and then "Finish"
7. Start the emulator by clicking the "Play" button

## Step 7: Run the Application

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

## Step 8: Grant Permissions

When you first run the app, you'll need to grant several permissions:

1. **Camera Permission**: Required for capturing images
2. **Microphone Permission**: Required for voice recognition
3. **Internet Permission**: Required for communicating with RunPod service

Grant these permissions when prompted by the app.

## Step 9: Test the Application

Once the app is running:

1. Grant all required permissions when prompted
2. Tap "Simulate Trigger" to test the workflow
3. Verify status indicators update correctly
4. Check connection status shows "Connected" when RunPod service is available

## Building APK for Distribution

To build a release APK:

```bash
flutter build apk --release
```

The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

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

## Next Steps

After successfully installing and running the app:

1. Test all functionality including voice recognition, camera, and TTS
2. Review the user guide for detailed usage instructions
3. Check the troubleshooting guide if you encounter any issues
4. Refer to the performance optimization guide for best practices

## Updating the Application

To update the application to the latest version:

1. Pull the latest changes:
   ```bash
   git pull origin main
   ```
2. Update dependencies:
   ```bash
   flutter pub get
   ```
3. Rebuild the app:
   ```bash
   flutter run
   ```

## Feedback and Support

If you encounter any issues during installation or have suggestions for improvement:

1. Check the troubleshooting guide
2. Review existing GitHub issues
3. Create a new issue if your problem hasn't been reported
4. Contact the development team for support
