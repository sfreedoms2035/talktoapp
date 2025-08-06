import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
import logging
import os

# Configure logging
logger = logging.getLogger(__name__)

def load_model():
    """
    Load the Qwen 2.5 VL model
    """
    try:
        logger.info("Loading Qwen 2.5 VL model...")
        
        # Model name
        model_name = "Qwen/Qwen2.5-VL-3B-Instruct"
        
        # Get Hugging Face token from environment variable
        hf_token = os.getenv("HF_TOKEN")
        
        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            trust_remote_code=True,
            token=hf_token  # Use token if available
        )
        
        # Load model
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            trust_remote_code=True,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto",
            token=hf_token  # Use token if available
        )
        
        # Set model to evaluation mode
        model.eval()
        
        # Determine device
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        logger.info(f"Model loaded successfully on {device}")
        return model, tokenizer, device
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise e
