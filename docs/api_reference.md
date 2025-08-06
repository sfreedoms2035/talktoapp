# TalkToApp API Reference

This document provides detailed information about the API endpoints available in the TalkToApp RunPod server.

## Base URL

```
http://<RUNPOD_IP>:8000
```

Replace `<RUNPOD_IP>` with the actual IP address of your RunPod instance.

## Health Check Endpoint

### GET /health

Check the health status of the server and model loading status.

#### Request
```
GET /health
```

#### Response
```json
{
  "status": "ready",
  "model_loaded": true,
  "timestamp": 1640995200.0
}
```

#### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| status | string | Current server status (initializing, loading_model, ready, error, processing) |
| model_loaded | boolean | Indicates if the AI model has been successfully loaded |
| timestamp | number | Unix timestamp of the response |

#### Possible Status Values
- `initializing`: Server is starting up
- `loading_model`: Model is being loaded
- `ready`: Server is ready to process requests
- `error`: An error occurred
- `processing`: Server is currently processing a request

## Status Endpoint

### GET /status

Get detailed status information about the server including request statistics.

#### Request
```
GET /status
```

#### Response
```json
{
  "status": "ready",
  "model_loaded": true,
  "last_request_time": 1640995200.0,
  "request_count": 42
}
```

#### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| status | string | Current server status |
| model_loaded | boolean | Indicates if the AI model has been successfully loaded |
| last_request_time | number | Unix timestamp of the last processed request |
| request_count | integer | Total number of requests processed |

## Process Endpoint

### POST /process

Process a multimodal request containing text and an image.

#### Request
```
POST /process
Content-Type: multipart/form-data

Form Data:
- text: "What is in this image?"
- image: [JPEG image file]
```

#### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| text | string | Yes | User's text query about the image |
| image | file | Yes | Image file (JPEG format recommended) |

#### Response (Success)
```json
{
  "response": "This image shows a beautiful landscape with mountains and a lake.",
  "timestamp": 1640995200.0
}
```

#### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| response | string | AI-generated response to the user's query |
| timestamp | number | Unix timestamp of the response |

#### Response (Error)
```json
{
  "error": "Failed to process request",
  "details": "Model not loaded"
}
```

#### Error Response Fields
| Field | Type | Description |
|-------|------|-------------|
| error | string | General error message |
| details | string | Detailed error information |

#### HTTP Status Codes
| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad request (missing parameters) |
| 500 | Internal server error |
| 503 | Service unavailable (model not loaded) |

## Example Usage

### Python Example
```python
import requests

# Server URL
url = "http://YOUR_RUNPOD_IP:8000/process"

# Prepare data
data = {
    "text": "What objects can you see in this image?"
}

# Prepare image file
files = {
    "image": open("image.jpg", "rb")
}

# Send request
response = requests.post(url, data=data, files=files)

# Process response
if response.status_code == 200:
    result = response.json()
    print("AI Response:", result["response"])
else:
    print("Error:", response.status_code, response.text)
```

### cURL Example
```bash
curl -X POST "http://YOUR_RUNPOD_IP:8000/process" \
  -F "text=What is in this image?" \
  -F "image=@image.jpg"
```

### JavaScript Example
```javascript
const formData = new FormData();
formData.append('text', 'What is in this image?');
formData.append('image', fileInput.files[0]);

fetch('http://YOUR_RUNPOD_IP:8000/process', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(data => {
  console.log('AI Response:', data.response);
})
.catch(error => {
  console.error('Error:', error);
});
```

## Error Handling

The API provides detailed error messages to help with debugging:

1. **Model Not Loaded (503)**: The AI model failed to load or is still loading
2. **Bad Request (400)**: Missing required parameters
3. **Internal Server Error (500)**: Unexpected error during processing

Always check the HTTP status code and error details in the response body for troubleshooting.

## Performance Considerations

1. **Image Size**: Large images will increase processing time. The server automatically resizes images to a maximum of 512px on the longest side.
2. **Network Latency**: API response time depends on network conditions between the client and server.
3. **Model Processing Time**: Complex queries may take longer to process.

## Rate Limiting

The current implementation does not include rate limiting, but it's recommended to implement client-side throttling to avoid overwhelming the server.

## Security

For production use, consider implementing:
1. HTTPS encryption
2. Authentication tokens
3. Input validation
4. Request size limits
