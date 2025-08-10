# TalkToApp RunPod Service Deployment Guide

This guide explains how to properly deploy and configure the RunPod service for the TalkToApp project.

## Prerequisites

- Docker installed
- RunPod account
- Python 3.8+
- Required Python packages (see requirements.txt)

## Local Development Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the Service Locally

```bash
python main.py
```

The service will be available at `http://localhost:8000`

### 3. Test the Service

```bash
# Health check
curl http://localhost:8000/health

# Get status
curl http://localhost:8000/status
```

## RunPod Deployment

### 1. Docker Configuration

The service uses the following Docker configuration:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "main.py"]
```

### 2. Port Configuration

**Important**: Ensure port 8000 is properly exposed in your RunPod configuration:

- Container Port: 8000
- Host Port: 8000 (or any available port)
- Protocol: TCP

### 3. Environment Variables

Set these environment variables in your RunPod configuration:

```bash
# Optional: Set custom port (default is 8000)
PORT=8000
```

## Troubleshooting Common Issues

### Issue 1: Connection Refused from Android App

**Symptoms**: 
- Android app shows "Failed to connect to server"
- curl requests to the public IP fail

**Diagnosis**:
1. Check if the service is running:
   ```bash
   # Inside the container
   python test_connection.py
   ```

2. Verify port binding:
   ```bash
   # Inside the container
   netstat -tuln | grep 8000
   ```

**Solutions**:
1. **Port Mapping**: Ensure RunPod is configured to expose port 8000
2. **Firewall**: Check if firewall rules allow connections on port 8000
3. **Security Groups**: If using cloud services, verify security group rules

### Issue 2: Model Loading Failures

**Symptoms**:
- Service starts but model fails to load
- Health check shows `model_loaded: false`

**Solutions**:
1. Check available GPU memory:
   ```bash
   nvidia-smi
   ```

2. Try loading a smaller model variant
3. Increase allocated GPU memory in RunPod configuration

### Issue 3: Slow Response Times

**Symptoms**:
- Long delays in processing requests
- Timeouts in Android app

**Solutions**:
1. **Image Size**: The service automatically resizes images to 512px for performance
2. **Model Optimization**: Consider using quantized models
3. **Caching**: Enable model caching in RunPod

## Network Configuration Checklist

### For RunPod:

1. [ ] Container port 8000 is exposed
2. [ ] Host port is mapped correctly
3. [ ] Security groups allow inbound connections on port 8000
4. [ ] Firewall rules permit traffic on port 8000
5. [ ] Public IP is accessible from the internet

### For Testing:

1. **Local Testing**:
   ```bash
   curl http://localhost:8000/health
   ```

2. **Internal IP Testing**:
   ```bash
   # Get container IP
   hostname -I
   curl http://[CONTAINER_IP]:8000/health
   ```

3. **External Testing**:
   ```bash
   curl http://[PUBLIC_IP]:8000/health
   ```

## Performance Optimization

### 1. Image Processing
- Images are automatically resized to 512px maximum dimension
- JPEG compression is used for faster transfer

### 2. Model Loading
- Model is loaded once at startup
- Consider using RunPod's persistent storage for faster model loading

### 3. Memory Management
- Monitor GPU memory usage
- Consider using 4-bit quantized models for lower memory usage

## Monitoring and Logging

### Health Endpoints:
- `/health` - Basic health check
- `/status` - Detailed status information

### Log Monitoring:
```bash
# View logs in RunPod
tail -f /var/log/runpod/service.log
```

## Common RunPod Configuration

### GPU Selection:
- Recommended: NVIDIA A100, V100, or RTX 3090
- Minimum: 16GB VRAM for Qwen2.5-VL-3B model

### Container Settings:
- Container Disk: 50GB+
- Volume Mount: For persistent model storage
- Environment Variables: As needed

## Debugging Tools

### 1. Network Diagnostic Script
Run the included diagnostic script:
```bash
python test_connection.py
```

### 2. Manual Testing
Test endpoints manually:
```bash
# Health check
curl -v http://[YOUR_IP]:8000/health

# Process request (example)
curl -X POST http://[YOUR_IP]:8000/process \
  -F "text=What is in this image?" \
  -F "image=@test_image.jpg"
```

## Security Considerations

### 1. API Security
- Currently no authentication (for development)
- Consider adding API keys for production

### 2. Rate Limiting
- No built-in rate limiting
- Consider implementing at the network level

### 3. Input Validation
- Basic input validation is implemented
- Consider additional validation for production use

## Updating the Service

### 1. Code Updates
1. Push changes to your repository
2. Rebuild the Docker image
3. Redeploy to RunPod

### 2. Model Updates
1. Update `model_loader.py` with new model information
2. Ensure sufficient disk space for new models
3. Test thoroughly before deployment

## Support

For issues with the RunPod deployment:

1. Check RunPod documentation: https://docs.runpod.io/
2. Verify your configuration matches this guide
3. Contact RunPod support if infrastructure issues persist
4. For application issues, check the service logs and health endpoints

## Quick Reference

### Service Endpoints:
- `GET /health` - Health check
- `GET /status` - Detailed status
- `POST /process` - Process multimodal input

### Required Files:
- `main.py` - Main application
- `model_loader.py` - Model loading logic
- `multimodal_processor.py` - Processing logic
- `requirements.txt` - Dependencies

### Common Commands:
```bash
# Start service
python main.py

# Test health
curl http://localhost:8000/health

# Test processing
curl -X POST http://localhost:8000/process \
  -F "text=What is in this image?" \
  -F "image=@test.jpg"
