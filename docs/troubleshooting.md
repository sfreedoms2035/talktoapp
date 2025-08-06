# TalkToApp Troubleshooting Guide

This guide provides solutions to common issues you may encounter when using TalkToApp.

## Android App Issues

### 1. App Crashes on Startup

**Symptoms**: App closes immediately after opening

**Solutions**:
1. Check Android version compatibility (API 21+ required)
2. Verify sufficient storage space available
3. Reinstall the app
4. Check logcat for specific error messages:
   ```bash
   flutter logs
   ```

### 2. Voice Recognition Not Working

**Symptoms**: App doesn't respond to voice commands or "Hey monitor" trigger

**Solutions**:
1. Ensure microphone permission is granted
2. Check device audio settings and volume
3. Verify internet connectivity for Whisper service
4. Test with different trigger phrases
5. Restart the app

### 3. Camera Not Functioning

**Symptoms**: Black screen or camera error messages

**Solutions**:
1. Ensure camera permission is granted
2. Check if another app is using the camera
3. Restart the device
4. Verify rear camera is functional in other apps
5. Clear app cache and data

### 4. Connection to RunPod Server Fails

**Symptoms**: "Disconnected" status, no response from server

**Solutions**:
1. Verify RunPod server IP address in `communication_service.dart`
2. Check network connectivity on device
3. Ensure RunPod server is running and accessible
4. Verify port 8000 is exposed on RunPod
5. Test server connectivity with curl:
   ```bash
   curl http://YOUR_RUNPOD_IP:8000/health
   ```

### 5. Text-to-Speech Not Working

**Symptoms**: No audio response from the app

**Solutions**:
1. Check device volume settings
2. Ensure app has audio playback permissions
3. Test device's text-to-speech engine in settings
4. Restart the app
5. Check for audio conflicts with other apps

### 6. Slow Performance

**Symptoms**: Delays in response or UI updates

**Solutions**:
1. Close other resource-intensive apps
2. Check device storage space
3. Ensure stable internet connection
4. Restart the device
5. Clear app cache

## RunPod Server Issues

### 1. Model Loading Failures

**Symptoms**: Server status shows "error" or "loading_model" indefinitely

**Solutions**:
1. Check internet connectivity
2. Verify sufficient disk space (15GB+ recommended)
3. Ensure GPU drivers are properly installed
4. Check logs for specific error messages
5. Restart the pod to clear any cached errors

### 2. Out of Memory Errors

**Symptoms**: CUDA out of memory errors, server crashes

**Solutions**:
1. Verify GPU has sufficient VRAM (16GB+ recommended)
2. Restart the pod to clear GPU memory
3. Consider upgrading to a more powerful GPU
4. Check for memory leaks in custom code

### 3. Slow Response Times

**Symptoms**: Long delays between request and response

**Solutions**:
1. Check GPU utilization:
   ```bash
   nvidia-smi
   ```
2. Verify image sizes are reasonable (auto-resized to 512px max)
3. Check network latency between client and server
4. Consider upgrading GPU for better performance

### 4. API Endpoint Not Accessible

**Symptoms**: Connection refused errors when accessing endpoints

**Solutions**:
1. Verify port 8000 is exposed in RunPod settings
2. Check if the server is actually running
3. Ensure firewall settings allow connections
4. Test with curl from the pod:
   ```bash
   curl http://localhost:8000/health
   ```

### 5. High Resource Usage

**Symptoms**: High CPU/GPU usage, increased costs

**Solutions**:
1. Monitor resource usage:
   ```bash
   nvidia-smi
   top
   ```
2. Implement request rate limiting
3. Consider horizontal scaling for high traffic
4. Optimize image preprocessing parameters

## Network and Connectivity Issues

### 1. Intermittent Connection Loss

**Symptoms**: Connection status toggles between connected and disconnected

**Solutions**:
1. Check network stability on both client and server
2. Verify RunPod instance is not restarting
3. Implement connection retry logic in client
4. Use connection pooling for better stability

### 2. Firewall Blocking Requests

**Symptoms**: Consistent connection timeouts

**Solutions**:
1. Verify port 8000 is open on RunPod
2. Check client device firewall settings
3. Test with different network connection
4. Use VPN if corporate firewall is blocking

## Performance Issues

### 1. Image Processing Delays

**Symptoms**: Long delays when processing images

**Solutions**:
1. Verify image compression is working
2. Check image dimensions (should be auto-resized)
3. Monitor GPU utilization during processing
4. Consider preprocessing images on the client side

### 2. Model Inference Slow

**Symptoms**: Long delays in generating responses

**Solutions**:
1. Verify using 4-bit quantized model
2. Check GPU memory usage
3. Consider upgrading GPU
4. Optimize prompt engineering for faster responses

## Error Messages and Solutions

### "Model not loaded" (503)
- Ensure the model has finished loading
- Check logs for loading errors
- Verify internet connectivity for model download

### "Failed to process request" (500)
- Check server logs for specific error details
- Verify input parameters are correct
- Ensure sufficient system resources

### "Connection timeout"
- Verify server IP and port are correct
- Check network connectivity
- Ensure server is running and accessible

### "Permission denied"
- Grant required permissions in app settings
- Restart app to trigger permission requests again
- Check device security settings

## Debugging Tools and Techniques

### Android Debugging

1. **Flutter Logs**:
   ```bash
   flutter logs
   ```

2. **Android Studio Logcat**:
   - Open Logcat window
   - Filter by package name
   - Look for error messages

3. **Device Testing**:
   - Test on multiple devices
   - Check different Android versions
   - Verify hardware compatibility

### RunPod Debugging

1. **Server Logs**:
   ```bash
   # If using screen
   screen -r talktoapp
   ```

2. **System Monitoring**:
   ```bash
   nvidia-smi  # GPU usage
   top         # CPU usage
   free -h     # Memory usage
   ```

3. **Network Testing**:
   ```bash
   curl http://YOUR_RUNPOD_IP:8000/health
   ping YOUR_RUNPOD_IP
   ```

## Prevention Strategies

### 1. Regular Maintenance
- Monitor resource usage
- Update dependencies regularly
- Backup configurations
- Test after updates

### 2. Monitoring
- Set up alerts for server downtime
- Monitor API response times
- Track error rates
- Monitor costs

### 3. Testing
- Test after any configuration changes
- Verify functionality on different devices
- Check performance under various loads
- Validate error handling

## Contact Support

If you're unable to resolve an issue with the above solutions:

1. Check the project GitHub issues
2. Contact the development team
3. Provide detailed error logs and steps to reproduce
4. Include system specifications and environment details

## Contributing to Documentation

If you've solved an issue not covered in this guide:

1. Fork the repository
2. Update this document with your solution
3. Submit a pull request
4. Include steps to reproduce and solution details
