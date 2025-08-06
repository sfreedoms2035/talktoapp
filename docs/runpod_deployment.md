# RunPod Deployment Guide

This guide provides detailed instructions for deploying the TalkToApp server application on RunPod.

## Prerequisites

Before you begin, ensure you have:

1. **RunPod Account**: Sign up at https://www.runpod.io/
2. **Basic understanding of cloud computing concepts**
3. **Git** for version control

## RunPod Setup

### 1. Create a RunPod Account

1. Visit https://www.runpod.io/
2. Click "Sign Up" and create an account
3. Verify your email address
4. Add payment method (RunPod offers free credits for new users)

### 2. Create a New Pod

1. Log in to your RunPod account
2. Click "Deploy" > "New Pod"
3. Select the following configuration:
   - **Template**: PyTorch 2.0 (or similar with Python 3.8+ and CUDA support)
   - **GPU**: NVIDIA A10 or better (16GB+ VRAM recommended)
   - **Storage**: 50GB or more (for model storage)
   - **Network**: Enable both HTTP and HTTPS ports

### 3. Configure Pod Settings

1. **Name**: Give your pod a descriptive name (e.g., "talktoapp-server")
2. **GPU Type**: Select a GPU with at least 16GB VRAM
3. **Volume Size**: Allocate at least 50GB for model storage
4. **Exposed Ports**: Ensure port 8000 is exposed for the API
5. **Startup Script**: Leave empty for now

## Deployment Steps

### 1. Access Your Pod

Once your pod is running:

1. Click on your pod in the RunPod dashboard
2. Click "Connect" > "Connect to Pod" to open the terminal
3. Alternatively, use SSH if you prefer:
   ```bash
   ssh root@<POD_IP> -p <SSH_PORT>
   ```

### 2. Clone the Repository

In the pod terminal:

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone <repository-url>
cd talktoapp/runpod_app
```

### 3. Install Dependencies

```bash
# Update package list
apt update

# Install system dependencies (if needed)
apt install -y python3-pip

# Install Python dependencies
pip install -r requirements.txt
```

### 4. Configure Environment Variables

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

### 5. Start the Server

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

## Model Loading

The application automatically loads the `unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit` model on startup. This process may take several minutes depending on your internet connection and system performance.

### Model Download Progress

You can monitor the model download progress through the terminal output:

```
INFO: Loading Qwen 2.5-VL model...
INFO: Downloading model files...
INFO: Model loaded successfully on cuda
```

### Model Storage

The model files are cached in the Hugging Face cache directory:
```
~/.cache/huggingface/hub/
```

Ensure you have sufficient storage space (approximately 10-15GB for the 4-bit quantized model).

## Network Configuration

### Expose API Port

1. In the RunPod dashboard, go to your pod
2. Click "Settings" > "Network"
3. Ensure port 8000 is exposed:
   - Type: TCP
   - Port: 8000
   - Protocol: HTTP

### Get Your Pod's Public IP

1. In the RunPod dashboard, go to your pod
2. Note the "Public IP" address
3. Your API will be accessible at: `http://<PUBLIC_IP>:8000`

## Testing the Deployment

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

### Restart the Server

If needed, you can restart the server:

```bash
# Kill the current process
pkill -f main.py

# Start the server again
python main.py
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
- Consider using a more powerful GPU

#### 3. Connection Refused
- Verify port 8000 is exposed in RunPod settings
- Check if the server is running
- Ensure firewall settings allow connections

#### 4. Slow Response Times
- Check GPU utilization
- Verify image sizes are reasonable
- Consider upgrading GPU

### Debugging Steps

1. **Check Server Status**
   ```bash
   curl http://<PUBLIC_IP>:8000/health
   ```

2. **View Application Logs**
   ```bash
   # Check for error messages in the terminal
   ```

3. **Monitor System Resources**
   ```bash
   nvidia-smi
   top
   ```

4. **Test Network Connectivity**
   ```bash
   ping <PUBLIC_IP>
   ```

## Scaling and High Availability

### Horizontal Scaling

For production use with high traffic:

1. Deploy multiple RunPod instances
2. Use a load balancer to distribute requests
3. Implement shared storage for model files
4. Use a database for persistent data (if needed)

### Vertical Scaling

Upgrade your pod:
1. Stop the current pod
2. Create a new pod with better specifications
3. Migrate data and configuration
4. Update client applications with new IP

## Security Considerations

### HTTPS Encryption

For production use, consider implementing HTTPS:
1. Use a reverse proxy like Nginx with SSL termination
2. Obtain SSL certificate from Let's Encrypt
3. Configure domain name and DNS

### Authentication

Implement API authentication:
1. Add API key validation
2. Use JWT tokens for session management
3. Implement rate limiting

### Input Validation

The current implementation includes basic input validation, but consider:
1. Implementing file size limits
2. Adding content type validation
3. Sanitizing text inputs

## Backup and Recovery

### Model Files Backup

Model files are automatically cached. To backup:
1. Create a snapshot of your pod volume
2. Or manually copy model files:
   ```bash
   cp -r ~/.cache/huggingface /backup/location/
   ```

### Configuration Backup

Backup your configuration files:
```bash
# Backup .env file
cp ~/talktoapp/runpod_app/.env /backup/location/
```

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
