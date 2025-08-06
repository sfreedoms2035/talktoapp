import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Add the parent directory to the path so we can import the modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from model_loader import load_model

class TestModelLoader(unittest.TestCase):
    
    @patch('transformers.AutoProcessor.from_pretrained')
    @patch('transformers.AutoModelForCausalLM.from_pretrained')
    @patch('torch.cuda.is_available')
    def test_load_model_success(self, mock_cuda_available, mock_model_loader, mock_processor_loader):
        """Test successful model loading"""
        # Mock the dependencies
        mock_cuda_available.return_value = True
        mock_model = MagicMock()
        mock_processor = MagicMock()
        mock_model_loader.return_value = mock_model
        mock_processor_loader.return_value = mock_processor
        
        # Call the function
        model, processor, device = load_model()
        
        # Assertions
        self.assertEqual(model, mock_model)
        self.assertEqual(processor, mock_processor)
        self.assertEqual(str(device), "cuda")
        
        # Verify mocks were called
        mock_processor_loader.assert_called_once()
        mock_model_loader.assert_called_once()

    @patch('transformers.AutoProcessor.from_pretrained')
    @patch('transformers.AutoModelForCausalLM.from_pretrained')
    @patch('torch.cuda.is_available')
    def test_load_model_cpu_fallback(self, mock_cuda_available, mock_model_loader, mock_processor_loader):
        """Test model loading falls back to CPU when CUDA is not available"""
        # Mock the dependencies
        mock_cuda_available.return_value = False
        mock_model = MagicMock()
        mock_processor = MagicMock()
        mock_model_loader.return_value = mock_model
        mock_processor_loader.return_value = mock_processor
        
        # Call the function
        model, processor, device = load_model()
        
        # Assertions
        self.assertEqual(model, mock_model)
        self.assertEqual(processor, mock_processor)
        self.assertEqual(str(device), "cpu")

    @patch('transformers.AutoProcessor.from_pretrained')
    @patch('transformers.AutoModelForCausalLM.from_pretrained')
    def test_load_model_failure(self, mock_model_loader, mock_processor_loader):
        """Test model loading failure"""
        # Mock the dependencies to raise an exception
        mock_processor_loader.side_effect = Exception("Failed to load processor")
        
        # Assertions
        with self.assertRaises(Exception):
            load_model()

if __name__ == '__main__':
    unittest.main()
