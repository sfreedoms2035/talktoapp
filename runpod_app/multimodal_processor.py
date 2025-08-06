import torch
from PIL import Image
import logging

# Configure logging
logger = logging.getLogger(__name__)

def process_multimodal_input(text, image, model, processor, device):
    """
    Process multimodal input (text + image) using Qwen 2.5-VL model
    
    Args:
        text (str): User's text query
        image (PIL.Image): Captured image
        model: Loaded Qwen model
        processor: Model processor
        device: Computing device (CPU/GPU)
        
    Returns:
        str: Model's response text
    """
    try:
        logger.info(f"Processing multimodal input: {text}")
        
        # Prepare the conversation
        conversation = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": text},
                    {"type": "image"}
                ]
            }
        ]
        
        # Process the inputs
        prompt = processor.apply_chat_template(
            conversation, 
            tokenize=False, 
            add_generation_prompt=True
        )
        
        # Prepare image inputs
        image_inputs = processor(images=image, return_tensors="pt")
        
        # Prepare text inputs
        text_inputs = processor(text=prompt, return_tensors="pt")
        
        # Move inputs to device
        inputs = {k: v.to(device) for k, v in {**text_inputs, **image_inputs}.items()}
        
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
        response_text = processor.decode(
            output[0][text_inputs['input_ids'].shape[1]:], 
            skip_special_tokens=True
        )
        
        logger.info("Response generated successfully")
        return response_text.strip()
        
    except Exception as e:
        logger.error(f"Error processing multimodal input: {e}")
        return f"Error processing your request: {str(e)}"
