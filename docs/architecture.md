# TalkToApp Architecture

This document describes the overall architecture of the TalkToApp project, including both the Android client and RunPod server components.

## System Overview

TalkToApp is a voice-triggered multimodal AI application that allows users to interact with an AI model through voice commands and visual context. The system consists of two main components:

1. **Android Client**: Captures user input (voice and images) and presents AI responses
2. **RunPod Server**: Processes multimodal inputs using the Qwen 2.5-VL model and generates responses

## High-Level Architecture

```
┌─────────────────────┐    Voice/Text/Img    ┌─────────────────────┐
│   Android Client    │ ◄───────────────────► │   RunPod Server     │
│                     │    JSON/HTTP API      │                     │
│ ┌─────────────────┐ │                       │ ┌─────────────────┐ │
│ │  Voice Service  │ │                       │ │  Qwen 2.5-VL    │ │
│ ├─────────────────┤ │                       │ │     Model       │ │
│ │ Camera Service  │ │                       │ └─────────────────┘ │
│ ├─────────────────┤ │                       │ ┌─────────────────┐ │
│ │Comm. Service    │ │                       │ │ FastAPI Server  │ │
│ ├─────────────────┤ │                       │ └─────────────────┘ │
│ │   TTS Service   │ │                       │ ┌─────────────────┐ │
│ └─────────────────┘ │                       │ │ Model Loader    │ │
│ ┌─────────────────┐ │                       │ └─────────────────┘ │
│ │   UI Components │ │                       │ ┌─────────────────┐ │
│ └─────────────────┘ │                       │ │ Image Processor │ │
│ ┌─────────────────┐ │                       │ └─────────────────┘ │
│ │   App State     │ │                       │ ┌─────────────────┐ │
│ └─────────────────┘ │                       │ │   Utilities     │ │
│                     │                       │ └─────────────────┘ │
└─────────────────────┘                       └─────────────────────┘
```

## Android Client Architecture

### Core Services

1. **Voice Service**
   - Uses Whisper for speech-to-text conversion
   - Handles voice trigger detection ("Hey monitor")
   - Manages audio recording and processing

2. **Camera Service**
   - Controls rear camera operations
   - Captures and compresses images
   - Manages camera lifecycle

3. **Communication Service**
   - Handles HTTP communication with RunPod server
   - Manages API endpoints and data serialization
   - Implements error handling and retries

4. **TTS Service**
   - Converts text responses to speech
   - Manages audio playback
   - Handles different voice settings

### UI Components

1. **Status Indicator**
   - Visual representation of application state
   - Color-coded status feedback

2. **Trigger Display**
   - Shows trigger word detection status
   - Visual feedback for "Hey monitor" detection

3. **Connection Status**
   - Displays connection state with RunPod server
   - Network connectivity monitoring

### State Management

- Uses Provider for reactive state management
- Centralized AppState model
- Real-time UI updates

## RunPod Server Architecture

### Core Components

1. **FastAPI Server**
   - RESTful API endpoints
   - Request/response handling
   - Health and status monitoring

2. **Model Loader**
   - Loads Qwen 2.5-VL model with 4-bit quantization
   - GPU/CUDA initialization
   - Error handling for model loading

3. **Multimodal Processor**
   - Processes text and image inputs
   - Interacts with Qwen model
   - Generates AI responses

4. **Image Processor**
   - Resizes and optimizes images
   - Format conversion
   - Performance optimization

### Data Flow

1. **Request Processing**
   - Receive multipart form data (text + image)
   - Validate inputs
   - Preprocess data

2. **Model Inference**
   - Format inputs for Qwen model
   - Execute inference
   - Process outputs

3. **Response Generation**
   - Format AI response
   - Return JSON response

## Communication Protocol

### API Endpoints

1. **Health Check**
   ```
   GET /health
   Response: {status, model_loaded, timestamp}
   ```

2. **Status**
   ```
   GET /status
   Response: {status, model_loaded, last_request_time, request_count}
   ```

3. **Process Request**
   ```
   POST /process
   Form Data: text (string), image (file)
   Response: {response, timestamp}
   ```

### Data Format

- **Text**: UTF-8 encoded strings
- **Images**: JPEG format (automatically compressed)
- **Responses**: JSON format

## Performance Considerations

### Android Client
- Image compression before transmission
- Background processing for heavy operations
- Efficient state management
- Connection pooling

### RunPod Server
- 4-bit quantized model for memory efficiency
- GPU acceleration
- Image preprocessing for faster inference
- Optimized generation parameters

## Security Considerations

- HTTPS communication (recommended)
- Input validation
- Error handling without exposing internals
- Secure storage of sensitive data

## Scalability

### Horizontal Scaling
- Multiple RunPod instances with load balancing
- Stateless server design
- Caching mechanisms

### Vertical Scaling
- GPU upgrades for better performance
- Memory optimization
- Model optimization techniques

## Monitoring and Logging

### Android Client
- State change logging
- Error tracking
- Performance metrics

### RunPod Server
- Request logging
- Model performance metrics
- Error tracking
- Resource utilization monitoring
