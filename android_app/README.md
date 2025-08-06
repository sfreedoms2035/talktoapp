# TalkToApp Android Application

This is the Android client application for the TalkToApp project. It captures images, converts voice to text, and communicates with the RunPod service to provide intelligent responses.

## Features
- Voice-triggered activation with "Hey monitor"
- Rear camera image capture with automatic compression
- Whisper-based speech-to-text conversion
- Text-to-speech response playback
- Real-time status monitoring
- Connection state tracking

## Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio
- Android device with API level 21 or higher
- Microphone and camera permissions

## Setup Instructions

### 1. Flutter Environment Setup
1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Install Android Studio: https://developer.android.com/studio
3. Run `flutter doctor` to verify your setup

### 2. Project Setup
```bash
# Clone the repository
git clone <repository-url>
cd android_app

# Install dependencies
flutter pub get
```

### 3. Configuration
Before running the app, you need to configure the RunPod server URL:

1. Open `lib/services/communication_service.dart`
2. Update the `_baseUrl` constant with your RunPod server IP:
   ```dart
   static const String _baseUrl = 'http://YOUR_RUNPOD_IP:8000';
   ```

### 4. Running the Application
```bash
# Connect an Android device or start an emulator
flutter devices

# Run the app
flutter run
```

## Permissions
The app requires the following permissions:
- Camera: For capturing images
- Microphone: For voice recognition
- Internet: For communicating with RunPod service

These permissions are automatically requested on first use.

## Architecture

### Core Components
1. **Voice Service**: Handles speech-to-text conversion using the speech_to_text package
2. **Camera Service**: Manages camera operations and image capture
3. **Communication Service**: Handles API communication with RunPod service
4. **TTS Service**: Converts text responses to speech
5. **App State**: Centralized state management using Provider

### UI Components
1. **Status Indicator**: Shows current application status
2. **Trigger Display**: Displays trigger word detection status
3. **Connection Status**: Shows connection state with RunPod service

## Performance Optimization

1. **Image Compression**: Images are automatically compressed before transmission
2. **Efficient State Management**: Uses Provider for reactive UI updates
3. **Background Processing**: Heavy operations run in background isolates
4. **Connection Pooling**: Reuses HTTP connections for better performance

## Testing

### Running Unit Tests
```bash
flutter test
```

### Manual Testing
1. Grant necessary permissions when prompted
2. Tap "Simulate Trigger" to test the workflow
3. Verify status indicators update correctly
4. Check connection status shows "Connected" when RunPod service is available

## Troubleshooting

### Common Issues
1. **Permission Denied**: Ensure all required permissions are granted
2. **Connection Failed**: Verify RunPod server is running and accessible
3. **Voice Recognition Not Working**: Check microphone permissions and internet connection
4. **Camera Not Working**: Ensure camera permissions are granted

### Logs
Use Android Studio's logcat or run `flutter logs` to view detailed logs.

## Contributing
See the main project README for contribution guidelines.
