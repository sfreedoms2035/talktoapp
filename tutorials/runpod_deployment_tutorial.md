# RunPod Deployment Tutorial

This tutorial provides step-by-step instructions for deploying the TalkToApp server application on RunPod.

## Prerequisites

Before you begin, ensure you have:

1. A RunPod account (sign up at https://www.runpod.io/)
2. Basic understanding of cloud computing concepts
3. Git installed on your local machine
4. An SSH client (optional, for advanced users)

## Step 1: Create a RunPod Account

1. Visit https://www.runpod.io/
2. Click "Sign Up" and create an account
3. Verify your email address
4. Add a payment method (RunPod offers free credits for new users)

## Step 2: Create a New Pod

1. Log in to your RunPod account
2. Click "Deploy" > "New Pod"
3. Select the following configuration:
   - **Template**: PyTorch 2.0 (or similar with Python 3.8+ and CUDA support)
   - **GPU**: NVIDIA A10 or better (16GB+ VRAM recommended)
   - **Storage**: 50GB or more (for model storage)
   - **Network**: Enable both HTTP and HTTPS ports

4. Configure Pod Settings:
   - **Name**: Give your pod a descriptive name (e.g., "talktoapp-server")
   - **GPU Type**: Select a GPU with at least 16GB VRAM
   - **Volume Size**: Allocate at least 50GB for model storage
   - **Exposed Ports**: Ensure port 8000 is exposed for the API
   - **Startup Script**: Leave empty for now

5. Click "Deploy Pod"

## Step 3: Access Your Pod

Once your pod is running (this may take a few minutes):

1. Click on your pod in the RunPod dashboard
2. Click "Connect" > "Connect to Pod" to open the terminal
3. Alternatively, use SSH if you prefer:
   ```bash
   ssh root@<POD_IP> -p <SSH_PORT>
   ```

## Step 4: Clone the Repository

In the pod terminal:

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone <repository-url>
cd talktoapp/runpod_app
```

## Step 5: Install Dependencies

```bash
# Update package list
apt update

# Install system dependencies (if needed)
apt install -y python3-pip

# Install Python dependencies
pip install -r requirements.txt
```

## Step 6: Configure Environment Variables

Create a `.env` file in the `runpod_app` directory:

```bash
# Navigate to the app directory
cd ~/talktoapp/runpod_app

# Create .env file
cat > .env << EOF
MODEL_NAME=unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit
HOST=0.0.0.0
PORT=8000
DEBUG=False
EOF
```

## Step 7: Start the Server

```bash
# Navigate to the app directory
cd ~/talktoapp/runpod_app

# Start the server
python main.py
```

For production use, consider using a process manager like `screen` or `tmux`:

```bash
# Using screen
screen -S talktoapp
python main.py

# Detach from screen: Ctrl+A, then D
# Reattach with: screen -r talktoapp
```

## Step 8: Monitor Model Loading

The application automatically loads the `unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit` model on startup. This process may take several minutes depending on your internet connection and system performance.

Watch the terminal output for progress messages:
```
INFO: Loading Qwen 2.5-VL model...
INFO: Downloading model files...
INFO: Model loaded successfully on cuda
```

## Step 9: Configure Network Settings

1. In the RunPod dashboard, go to your pod
2. Click "Settings" > "Network"
3. Ensure port 8000 is exposed:
   - Type: TCP
   - Port: 8000
   - Protocol: HTTP

## Step 10: Get Your Pod's Public IP

1. In the RunPod dashboard, go to your pod
2. Note the "Public IP" address
3. Your API will be accessible at: `http://<PUBLIC_IP>:8000`

## Step 11: Test the Deployment

### Health Check

Test the health endpoint:
```bash
curl http://<PUBLIC_IP>:8000/health
```

Expected response:
```json
{
  "status": "ready",
  "model_loaded": true,
  "timestamp": 1640995200.0
}
```

### Process Test

Test the process endpoint with a sample request:
```bash
curl -X POST "http://<PUBLIC_IP>:8000/process" \
  -F "text=What is in this image?" \
  -F "image=@sample.jpg"
```

## Step 12: Configure Android App

Update the Android app to use your RunPod server:

1. Open `android_app/lib/services/communication_service.dart`
2. Update the `_baseUrl` constant:
   ```dart
   static const String _baseUrl = 'http://<PUBLIC_IP>:8000';
   ```
   
Replace `<PUBLIC_IP>` with your pod's Public IP address.

## Troubleshooting

### Common Issues and Solutions

#### 1. Model Loading Fails
- Check internet connectivity
- Verify sufficient disk space
- Ensure GPU drivers are installed
- Check logs for specific error messages

#### 2. Out of Memory Errors
- Verify GPU has sufficient VRAM (16GB+ recommended)
- Restart the pod to clear memory
- Consider upgrading to a more powerful GPU

#### 3. Connection Refused
- Verify port 8000 is exposed in RunPod settings
- Check if the server is running
- Ensure firewall settings allow connections

#### 4. Slow Response Times
- Check GPU utilization
- Verify image sizes are reasonable
- Consider upgrading GPU

## Monitoring and Maintenance

### View Logs

Check application logs in the terminal where you started the server, or use:

```bash
# If using screen
screen -r talktoapp

# View recent logs
tail -f /var/log/runpod/app.log
```

### Monitor Resource Usage

```bash
# Check GPU usage
nvidia-smi

# Check memory usage
free -h

# Check disk usage
df -h
```

## Performance Optimization

### GPU Memory Management

Monitor GPU memory usage:
```bash
nvidia-smi
```

If you encounter memory issues:
1. Ensure you're using the 4-bit quantized model
2. Restart the pod to clear GPU memory
3. Consider upgrading to a GPU with more VRAM

### Image Preprocessing

The server automatically resizes images to 512px max dimension to optimize processing time. This can be adjusted in `utils/image_processor.py`.

## Security Considerations

For production use, consider implementing:

1. **HTTPS Encryption**:
   - Use a reverse proxy like Nginx with SSL termination
   - Obtain SSL certificate from Let's Encrypt
   - Configure domain name and DNS

2. **Authentication**:
   - Add API key validation
   - Use JWT tokens for session management
   - Implement rate limiting

3. **Input Validation**:
   - Implement file size limits
   - Add content type validation
   - Sanitize text inputs

## Cost Management

### Monitor Usage

1. Check RunPod dashboard for usage statistics
2. Monitor GPU hours consumed
3. Set budget alerts in RunPod settings

### Optimize Costs

1. Use spot instances when possible
2. Shut down pods when not in use
3. Right-size GPU selection for your needs
4. Monitor idle time and optimize accordingly

## Updating the Application

### Pull Latest Changes

```bash
cd ~/talktoapp
git pull origin main
```

### Update Dependencies

```bash
cd ~/talktoapp/runpod_app
pip install -r requirements.txt --upgrade
```

### Restart Server

```bash
pkill -f main.py
python main.py
```

Always test the updated application to ensure compatibility.

## Next Steps

After successfully deploying the RunPod server:

1. Test all functionality with the Android app
2. Review the API reference for detailed endpoint information
3. Check the troubleshooting guide if you encounter any issues
4. Refer to the performance optimization guide for best practices
5. Set up monitoring for production use

## Feedback and Support

If you encounter any issues during deployment or have suggestions for improvement:

1. Check the troubleshooting guide
2. Review existing GitHub issues
3. Create a new issue if your problem hasn't been reported
4. Contact the development team for support
