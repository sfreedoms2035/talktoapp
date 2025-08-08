# TalkToApp API Reference

This document provides detailed information about the API endpoints available in the RunPod service for the TalkToApp project.

## Base URL

```
http://<runpod-server-ip>:8000
```

## Health Check Endpoint

### GET /health

Returns the current health status of the RunPod service.

#### Response

```json
{
  "status": "ready",
  "model_loaded": true,
  "timestamp": 1723123456.789
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| status | string | Current service status ("initializing", "loading_model", "ready", "processing", "error") |
| model_loaded | boolean | Indicates if the Qwen model has been successfully loaded |
| timestamp | number | Unix timestamp of the response |

#### Example

```bash
curl -X GET http://localhost:8000/health
```

## Status Endpoint

### GET /status

Returns detailed status information about the RunPod service.

#### Response

```json
{
  "status": "ready",
  "model_loaded": true,
  "last_request_time": 1723123456.789,
  "request_count": 42
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| status | string | Current service status |
| model_loaded | boolean | Indicates if the Qwen model has been successfully loaded |
| last_request_time | number | Unix timestamp of the last processed request |
| request_count | integer | Total number of requests processed since startup |

#### Example

```bash
curl -X GET http://localhost:8000/status
```

## Process Endpoint

### POST /process

Processes multimodal input (text + image) using the Qwen 2.5 VL model.

#### Request Format

Multipart form data with the following fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | User's text query |
| image | file | Yes | Image file (JPEG format recommended) |

#### Request Example

```bash
curl -X POST http://localhost:8000/process \
  -F "text=What is in this image?" \
  -F "image=@captured_image.jpg"
```

#### Response

```json
{
  "response": "The image shows a beautiful landscape with mountains and a lake.",
  "timestamp": 1723123456.789
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| response | string | AI-generated response to the input |
| timestamp | number | Unix timestamp of the response |

#### Error Response

```json
{
  "error": "Failed to process request",
  "details": "Model not loaded"
}
```

#### Error Response Codes

| HTTP Status | Error Message | Description |
|-------------|---------------|-------------|
| 503 | Model not loaded | The Qwen model failed to load or is not ready |
| 500 | Failed to process request | An error occurred during request processing |

## Data Formats

### Text Format

All text data should be UTF-8 encoded strings.

### Image Format

- **Format**: JPEG (recommended)
- **Maximum size**: Processed images are automatically resized to 512px max dimension
- **Color space**: RGB
- **Compression**: Images are optimized for faster processing

## Performance Considerations

### Request Timeout

The API has a default timeout of 30 seconds for processing requests. For complex queries or large images, responses may take longer.

### Rate Limiting

The current implementation does not include rate limiting. In production environments, consider implementing rate limiting to prevent abuse.

### Image Size Optimization

To minimize processing time:
1. Images are automatically resized to 512px max dimension
2. Large images will be compressed before processing
3. JPEG format is recommended for faster processing

## Error Handling

### Common Error Responses

| HTTP Status | Error Message | Description |
|-------------|---------------|-------------|
| 400 | Bad Request | Invalid request format or missing required fields |
| 413 | Request Entity Too Large | Uploaded image exceeds size limits |
| 500 | Internal Server Error | Unexpected error during processing |
| 503 | Service Unavailable | Service is not ready or model failed to load |

### Error Response Format

All error responses follow this format:

```json
{
  "error": "Error description",
  "details": "Additional details about the error"
}
```

## Implementation Details

### Model Loading

The Qwen 2.5 VL model is loaded once at startup:
- Model: `unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit`
- Quantization: 4-bit for memory efficiency
- Device: Automatically uses CUDA if available, falls back to CPU

### Image Processing

1. Images are resized to 512px max dimension while maintaining aspect ratio
2. Images are converted to RGB format if needed
3. Images are processed in memory without temporary file storage

### Text Processing

1. Text is processed as-is without additional preprocessing
2. Maximum token length for generation is 512 tokens
3. Generation parameters:
   - Temperature: 0.7
   - Top-p: 0.9
   - Do sample: True

## Security Considerations

### Authentication

The current API implementation does not include authentication. In production environments, consider:

1. Adding API key authentication
2. Implementing OAuth 2.0 for user authentication
3. Using HTTPS for encrypted communication

### Input Validation

1. Text inputs are sanitized to prevent injection attacks
2. Image files are validated for format and size
3. File extensions are checked to prevent malicious uploads

### Rate Limiting

Implement rate limiting to prevent abuse:
- Per-IP rate limiting
- Per-user rate limiting (if authentication is added)
- Burst rate limiting for sudden traffic spikes

## Monitoring and Logging

### Request Logging

All requests are logged with:
- Timestamp
- Client IP address
- Request method and endpoint
- Response status code
- Processing time

### Error Logging

Errors are logged with:
- Error message and stack trace
- Request details
- Client information
- Timestamp

### Performance Metrics

Performance metrics tracked:
- Average response time
- Request success rate
- Model processing time
- Memory usage

## Testing

### Health Check Test

```bash
curl -X GET http://localhost:8000/health
```

### Process Test

```bash
curl -X POST http://localhost:8000/process \
  -F "text=Describe this image" \
  -F "image=@test_image.jpg"
```

### Status Test

```bash
curl -X GET http://localhost:8000/status
```

## Troubleshooting

### Common Issues

1. **Model Loading Failure**
   - Check Hugging Face token
   - Verify internet connectivity
   - Check GPU memory availability

2. **Slow Response Times**
   - Check image size
   - Verify GPU utilization
   - Monitor system resources

3. **Connection Errors**
   - Verify service is running
   - Check firewall settings
   - Verify network connectivity

### Debugging Information

To get more detailed information about issues:
1. Check the service logs
2. Verify the health endpoint response
3. Test with a simple image and text query
