import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image
import io
import json
import base64
import logging
from ts.torch_handler.base_handler import BaseHandler

logger = logging.getLogger(__name__)

class AIImageDetectionHandler(BaseHandler):
    """
    TorchServe handler for AI-generated image detection
    """
    
    def __init__(self):
        super(AIImageDetectionHandler, self).__init__()
        self.initialized = False
        self.model = None
        self.device = None
        self.transform = None
        
    def initialize(self, context):
        """Initialize model and preprocessing"""
        try:
            logger.info("Initializing AI Image Detection Handler")
            
            # Set device
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            logger.info(f"Using device: {self.device}")
            
            # Load model (this would be your trained model)
            self.model = self._load_model()
            self.model.to(self.device)
            self.model.eval()
            
            # Define preprocessing transforms
            self.transform = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                                   std=[0.229, 0.224, 0.225])
            ])
            
            self.initialized = True
            logger.info("AI Image Detection Handler initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize handler: {e}")
            raise
    
    def _load_model(self):
        """Load the AI detection model"""
        # For production, load your trained model
        # This is a placeholder using a pre-trained model
        import torchvision.models as models
        
        # Using ResNet as a placeholder - in production, use your trained model
        model = models.resnet50(pretrained=True)
        
        # Modify for binary classification (real vs AI-generated)
        model.fc = nn.Linear(model.fc.in_features, 2)
        
        return model
    
    def preprocess(self, data):
        """Preprocess input data"""
        try:
            # Handle different input formats
            if isinstance(data[0].get("data"), (bytes, bytearray)):
                image_data = data[0].get("data")
            elif isinstance(data[0].get("body"), (bytes, bytearray)):
                image_data = data[0].get("body")
            elif isinstance(data[0].get("data"), str):
                # Base64 encoded image
                image_data = base64.b64decode(data[0].get("data"))
            else:
                raise ValueError("Unsupported input format")
            
            # Load image
            image = Image.open(io.BytesIO(image_data)).convert('RGB')
            
            # Apply transforms
            tensor = self.transform(image)
            tensor = tensor.unsqueeze(0)  # Add batch dimension
            
            return tensor.to(self.device)
            
        except Exception as e:
            logger.error(f"Preprocessing failed: {e}")
            raise
    
    def inference(self, data, *args, **kwargs):
        """Run model inference"""
        try:
            with torch.no_grad():
                output = self.model(data)
                probabilities = torch.nn.functional.softmax(output, dim=1)
                
                # Return probabilities for both classes
                real_prob = float(probabilities[0][0].item())
                ai_prob = float(probabilities[0][1].item())
                
                return {
                    "real_probability": real_prob,
                    "ai_generated_probability": ai_prob,
                    "prediction": "ai_generated" if ai_prob > 0.5 else "real",
                    "confidence": max(real_prob, ai_prob)
                }
                
        except Exception as e:
            logger.error(f"Inference failed: {e}")
            raise
    
    def postprocess(self, data):
        """Postprocess results"""
        try:
            # Convert to JSON-serializable format
            result = {
                "ai_detection": {
                    "is_ai_generated": data["prediction"] == "ai_generated",
                    "ai_probability": data["ai_generated_probability"],
                    "real_probability": data["real_probability"],
                    "confidence": data["confidence"],
                    "model_version": "1.0.0"
                }
            }
            
            return [json.dumps(result)]
            
        except Exception as e:
            logger.error(f"Postprocessing failed: {e}")
            raise

# Required for TorchServe
_service = AIImageDetectionHandler()


def handle(data, context):
    """Main handler function for TorchServe"""
    try:
        if not _service.initialized:
            _service.initialize(context)
        
        if data is None:
            return None
        
        # Preprocess
        input_data = _service.preprocess(data)
        
        # Inference
        inference_result = _service.inference(input_data)
        
        # Postprocess
        result = _service.postprocess(inference_result)
        
        return result
        
    except Exception as e:
        logger.error(f"Handler execution failed: {e}")
        return [json.dumps({"error": str(e)})]