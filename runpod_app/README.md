# RunPod Application for TalkToApp

This is the server-side component of the TalkToApp project that runs on RunPod. It handles processing of multimodal inputs (text + images) using the Qwen 2.5-VL model and returns intelligent responses.

## Features
- FastAPI web server for handling API requests
- Qwen 2.5-VL 3B model with 4-bit quantization for efficient inference
- Multimodal processing (text + image inputs)
- Real-time status monitoring
- Health check endpoints
- Comprehensive logging

## Prerequisites
- RunPod account
- NVIDIA GPU with at least 16GB VRAM (recommended)
- Python 3.8 or higher

## Setup Instructions

### 1. RunPod Environment Setup
1. Create a new RunPod instance with a GPU (recommended: NVIDIA A10 or better)
2. Select a template with Python 3.8+ and CUDA support
3. Allocate at least 30GB storage space

### 2. Install Dependencies
```bash
# Clone the repository
git clone <repository-url>
cd runpod_app

# Install Python dependencies
pip install -r requirements.txt
```

### 3. Model Loading
The application automatically loads the `unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit` model on startup. This 4-bit quantized version balances performance with memory efficiency.

### 4. Running the Application
```bash
# Start the server
python main.py
```

The server will start on port 8000.

## API Endpoints

### Health Check
```
GET /health
```
Returns the health status of the application.

### Status
```
GET /status
```
Returns detailed status information including request count and last request time.

### Process Request
```
POST /process
```
Process a multimodal request with text and image.

Form parameters:
- `text`: User's text query
- `image`: Image file (JPEG format recommended)

## Performance Optimization

1. **Model Quantization**: Uses 4-bit quantization to reduce memory usage
2. **Image Preprocessing**: Automatically resizes images to 512px max dimension
3. **GPU Acceleration**: Utilizes CUDA when available
4. **Efficient Inference**: Optimized generation parameters for speed

## Monitoring

The application provides real-time status updates through:
- `/status` endpoint
- Console logging
- Error tracking

## Troubleshooting

### Common Issues
1. **Model Loading Failures**: Ensure sufficient GPU memory is available
2. **CUDA Errors**: Verify CUDA drivers are properly installed
3. **Memory Issues**: Consider using a GPU with more VRAM

### Logs
Check the console output for detailed logging information.

## Contributing
See the main project README for contribution guidelines.
