import torch
from PIL import Image
import logging
import base64
from io import BytesIO

# Configure logging
logger = logging.getLogger(__name__)

def process_multimodal_input(text, image, model, tokenizer, image_processor, device):
    """
    Process multimodal input (text + image) using Qwen 2.5 VL model
    
    Args:
        text (str): User's text query
        image (PIL.Image): Captured image
        model: Loaded Qwen model
        tokenizer: Model tokenizer
        device: Computing device (CPU/GPU)
        
    Returns:
        str: Model's response text
    """
    try:
        logger.info(f"Processing multimodal input: {text}")
        
        # Convert image to base64 string
        buffered = BytesIO()
        image.save(buffered, format="JPEG")
        img_str = base64.b64encode(buffered.getvalue()).decode()
        
        # Format input for Qwen 2.5 VL
        # This format may need adjustment based on the specific model requirements
        conversation = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": text},
                    {
                        "type": "image",
                        "image": img_str
                    }
                ]
            }
        ]
        
        # Process the inputs using the model's specific method
        # This is a generic approach - you might need to adjust based on the model's requirements
        prompt = f"<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n<|im_start|>user\n<image>\n{text}<|im_end|>\n<|im_start|>assistant\n"
        
        # Tokenize the input
        inputs = tokenizer(
            prompt,
            return_tensors="pt",
            padding=True,
            truncation=True
        )
        
        # Move inputs to device
        inputs = {k: v.to(device) for k, v in inputs.items()}
        
        # Generate response
        with torch.no_grad():
            output = model.generate(
                **inputs,
                max_new_tokens=512,
                do_sample=True,
                temperature=0.7,
                top_p=0.9,
            )
        
        # Decode the response
        response_text = tokenizer.decode(output[0], skip_special_tokens=True)
        
        logger.info("Response generated successfully")
        return response_text.strip()
        
    except Exception as e:
        logger.error(f"Error processing multimodal input: {e}")
        return f"Error processing your request: {str(e)}"
