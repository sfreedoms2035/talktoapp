import torch
from PIL import Image
import logging
from qwen_vl_utils import process_vision_info

# Configure logging
logger = logging.getLogger(__name__)

def process_multimodal_input(text, image, model, tokenizer, processor, device):
    """
    Process multimodal input (text + image) using Qwen 2.5 VL model
    
    Args:
        text (str): User's text query
        image (PIL.Image): Captured image
        model: Loaded Qwen model
        tokenizer: Model tokenizer
        processor: Model processor
        device: Computing device (CPU/GPU)
        
    Returns:
        str: Model's response text
    """
    try:
        logger.info(f"Processing multimodal input: {text}")
        
        # Format input for Qwen 2.5 VL
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "image"},
                    {"type": "text", "text": text}
                ]
            }
        ]
        
        # Apply chat template
        text_prompt = processor.apply_chat_template(messages, add_generation_prompt=True)
        
        # Process inputs
        inputs = processor(
            text=[text_prompt],
            images=[image],
            return_tensors="pt",
            padding=True
        ).to(device)
        
        # Generate response
        with torch.no_grad():
            output_ids = model.generate(
                **inputs,
                max_new_tokens=512,
                do_sample=True,
                temperature=0.7,
                top_p=0.9,
            )
        
        # Decode the response
        response_text = processor.batch_decode(output_ids[:, inputs["input_ids"].size(1):], skip_special_tokens=True)[0]
        
        logger.info("Response generated successfully")
        return response_text.strip()
        
    except Exception as e:
        logger.error(f"Error processing multimodal input: {e}")
        return f"Error processing your request: {str(e)}"
