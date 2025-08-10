# TalkToApp - Voice-Triggered AI Assistant

A complete Android application that responds to voice commands, captures images, and processes them using a multimodal AI model running on RunPod.

## Overview

TalkToApp is an innovative Android application that:
1. Listens for voice trigger words ("Hey monitor")
2. Captures images from the rear camera when triggered
3. Sends the image and transcribed voice command to a RunPod service
4. Processes the input using Qwen2.5-VL multimodal AI model
5. Converts the AI response to speech and plays it back to the user

## Architecture

### Components

1. **Android Application** (Flutter/Dart)
   - Voice trigger detection using speech_to_text
   - Camera image capture
   - Network communication with RunPod service
   - Text-to-speech response playback
   - Real-time UI status updates

2. **RunPod Service** (Python/FastAPI)
   - Qwen2.5-VL-3B multimodal model
   - Image and text processing
   - REST API endpoints
   - Health monitoring and logging

### Data Flow

```
User speaks "Hey monitor" 
→ Android app detects trigger 
→ Camera captures image 
→ Image + transcribed text sent to RunPod 
→ AI processes multimodal input 
→ Response sent back to Android app 
→ Android converts text response to speech 
→ User hears AI response
```

## Prerequisites

### For Android App:
- Android device with camera and microphone
- Flutter SDK 3.0+
- Android Studio or VS Code with Flutter extensions

### For RunPod Service:
- RunPod account with GPU access
- Python 3.8+
- Docker (for containerization)
- 16GB+ VRAM GPU recommended

## Installation and Setup

### 1. Android Application Setup

```bash
# Clone the repository
git clone https://github.com/sfreedoms2035/talktoapp.git
cd talktoapp/android_app

# Install Flutter dependencies
flutter pub get

# Build the app
flutter build apk

# Install on connected Android device
flutter install
```

### 2. RunPod Service Setup

```bash
# Navigate to runpod_app directory
cd ../runpod_app

# Install Python dependencies
pip install -r requirements.txt

# Configure RunPod deployment
# Update main.py with your model preferences if needed
```

### 3. RunPod Deployment

1. Create a new RunPod template with:
   - Container Port: 8000
   - Volume: For persistent model storage
   - GPU: NVIDIA A100, V100, or RTX 3090 (16GB+ VRAM)

2. Deploy using the provided Docker configuration

3. Note the public IP address assigned by RunPod

### 4. Configure Android App

Update the RunPod service IP in `lib/services/communication_service.dart`:

```dart
static const String _baseUrl = 'http://[YOUR_RUNPOD_IP]:8000';
```

## Usage

### Running the Application

1. Start the RunPod service
2. Launch the Android app on your device
3. Grant necessary permissions (camera, microphone, storage)
4. Say "Hey monitor" to trigger the application
5. The app will capture an image and send it to the AI service
6. Listen for the AI's spoken response

### Features

- **Voice Trigger Detection**: Listens for "Hey monitor" phrase
- **Camera Integration**: Captures rear camera images automatically
- **Real-time Status Updates**: Visual feedback on app state
- **Network Monitoring**: Connection status to RunPod service
- **Error Handling**: Graceful handling of network and processing errors
- **Performance Optimized**: Fast response times and efficient processing

## API Endpoints

### RunPod Service Endpoints

- `GET /health` - Health check and status
- `GET /status` - Detailed application status
- `POST /process` - Process multimodal input (text + image)

## Performance and Optimization

### Latency Optimization

- Images automatically resized to 512px for faster processing
- 4-bit quantized models for reduced memory usage
- Connection pooling for efficient network requests
- Asynchronous processing for non-blocking operations

### Memory Management

- Model loaded once at startup
- Automatic garbage collection
- Efficient image processing pipeline
- Resource cleanup after each request

## Testing

### Automated Tests

Run the existing Flutter widget tests:

```bash
cd android_app
flutter test
```

### Manual Testing

Follow the comprehensive testing guide in `TESTING_GUIDE.md` for detailed testing procedures.

## Troubleshooting

### Common Issues

1. **Voice Trigger Not Detected**
   - Check microphone permissions
   - Test in quiet environment
   - Verify speech recognition settings

2. **Camera Not Working**
   - Check camera permissions
   - Verify hardware functionality
   - Test with different camera

3. **Network Connection Failed**
   - Verify RunPod service is running
   - Check firewall settings
   - Test network connectivity

4. **Slow AI Responses**
   - Monitor GPU memory usage
   - Check model loading status
   - Consider using smaller models

### Debugging

- Check Android logs: `adb logcat | grep talktoapp`
- Monitor RunPod logs via RunPod dashboard
- Test endpoints manually with curl

## Security Considerations

- Currently no authentication (development version)
- Consider implementing API keys for production
- Validate all input data
- Use HTTPS for production deployments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the documentation and testing guide
2. Review existing issues on GitHub
3. Contact the development team

## Future Enhancements

- Multi-language support
- Custom trigger phrase configuration
- Offline mode with local models
- Enhanced security features
- Additional AI model integrations
