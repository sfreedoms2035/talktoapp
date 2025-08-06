from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import uvicorn
import torch
from PIL import Image
import io
import json
import base64
import logging
from model_loader import load_model
from multimodal_processor import process_multimodal_input
from utils.image_processor import resize_image
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="TalkToApp RunPod Service", version="1.0.0")

# Global variables for model and state
model = None
processor = None
device = None
app_state = {
    "status": "initializing",
    "model_loaded": False,
    "last_request_time": None,
    "request_count": 0
}

@app.on_event("startup")
async def startup_event():
    """Load model when application starts"""
    global model, processor, device
    logger.info("Starting application and loading model...")
    
    try:
        app_state["status"] = "loading_model"
        model, processor, device = load_model()
        app_state["model_loaded"] = True
        app_state["status"] = "ready"
        logger.info("Model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        app_state["status"] = "error"
        app_state["error"] = str(e)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": app_state["status"],
        "model_loaded": app_state["model_loaded"],
        "timestamp": time.time()
    }

@app.get("/status")
async def get_status():
    """Get detailed status of the application"""
    return app_state

@app.post("/process")
async def process_request(
    text: str = Form(...),
    image: UploadFile = File(...)
):
    """Process multimodal input (text + image) and return AI response"""
    global model, processor, device
    
    if not app_state["model_loaded"]:
        return JSONResponse(
            status_code=503,
            content={"error": "Model not loaded"}
        )
    
    try:
        # Update state
        app_state["status"] = "processing"
        app_state["last_request_time"] = time.time()
        app_state["request_count"] += 1
        
        logger.info(f"Processing request: {text}")
        
        # Process image
        image_content = await image.read()
        image_pil = Image.open(io.BytesIO(image_content))
        
        # Resize image for performance
        image_pil = resize_image(image_pil, max_size=512)
        
        # Process with multimodal model
        response = process_multimodal_input(
            text, image_pil, model, processor, device
        )
        
        # Update state
        app_state["status"] = "ready"
        
        return JSONResponse(
            content={
                "response": response,
                "timestamp": time.time()
            }
        )
        
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        app_state["status"] = "error"
        app_state["error"] = str(e)
        
        return JSONResponse(
            status_code=500,
            content={
                "error": "Failed to process request",
                "details": str(e)
            }
        )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        workers=1
    )
