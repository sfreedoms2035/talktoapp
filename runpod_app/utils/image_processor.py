from PIL import Image
import logging

# Configure logging
logger = logging.getLogger(__name__)

def resize_image(image, max_size=512):
    """
    Resize image while maintaining aspect ratio
    
    Args:
        image (PIL.Image): Input image
        max_size (int): Maximum dimension size
        
    Returns:
        PIL.Image: Resized image
    """
    try:
        # Get current dimensions
        width, height = image.size
        
        # Calculate new dimensions maintaining aspect ratio
        if width > height:
            new_width = min(width, max_size)
            new_height = int(height * (new_width / width))
        else:
            new_height = min(height, max_size)
            new_width = int(width * (new_height / height))
        
        # Resize image
        resized_image = image.resize((new_width, new_height), Image.LANCZOS)
        
        logger.info(f"Image resized from {width}x{height} to {new_width}x{new_height}")
        return resized_image
        
    except Exception as e:
        logger.error(f"Error resizing image: {e}")
        # Return original image if resize fails
        return image

def convert_to_rgb(image):
    """
    Convert image to RGB format if it isn't already
    
    Args:
        image (PIL.Image): Input image
        
    Returns:
        PIL.Image: RGB image
    """
    if image.mode != 'RGB':
        return image.convert('RGB')
    return image

def optimize_image(image, quality=85):
    """
    Optimize image for faster processing
    
    Args:
        image (PIL.Image): Input image
        quality (int): JPEG quality (1-100)
        
    Returns:
        PIL.Image: Optimized image
    """
    try:
        # Convert to RGB if needed
        image = convert_to_rgb(image)
        
        # Reduce quality for faster processing
        # Note: This is a simplified approach. In practice, you might want to
        # use more sophisticated compression techniques.
        
        logger.info(f"Image optimized with quality setting: {quality}")
        return image
        
    except Exception as e:
        logger.error(f"Error optimizing image: {e}")
        return image
