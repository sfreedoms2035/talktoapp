import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, AutoProcessor
import logging

# Configure logging
logger = logging.getLogger(__name__)

def load_model():
    """
    Load the Qwen 2.5-VL model with 4-bit quantization for efficiency
    """
    try:
        logger.info("Loading Qwen 2.5-VL model...")
        
        # Model name
        #model_name = "unsloth/Qwen2.5-VL-3B-Instruct-unsloth-bnb-4bit"
        model_name = "Qwen/Qwen2.5-VL-3B-Instruct"
        
        # Load processor
        processor = AutoProcessor.from_pretrained(
            model_name,
            trust_remote_code=True
        )
        
        # Load model with 4-bit quantization
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            trust_remote_code=True,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto"
        )
        
        # Set model to evaluation mode
        model.eval()
        
        # Determine device
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        logger.info(f"Model loaded successfully on {device}")
        return model, processor, device
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise e
