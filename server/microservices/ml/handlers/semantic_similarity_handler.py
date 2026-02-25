import torch
import numpy as np
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import io
import json
import base64
import logging
from ts.torch_handler.base_handler import BaseHandler

logger = logging.getLogger(__name__)

class SemanticSimilarityHandler(BaseHandler):
    """
    TorchServe handler for semantic similarity and embedding extraction
    """
    
    def __init__(self):
        super(SemanticSimilarityHandler, self).__init__()
        self.initialized = False
        self.model = None
        self.processor = None
        self.device = None
        
    def initialize(self, context):
        """Initialize CLIP model and processor"""
        try:
            logger.info("Initializing Semantic Similarity Handler")
            
            # Set device
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            logger.info(f"Using device: {self.device}")
            
            # Load CLIP model
            self.model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
            self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
            
            self.model.to(self.device)
            self.model.eval()
            
            self.initialized = True
            logger.info("Semantic Similarity Handler initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize handler: {e}")
            raise
    
    def preprocess(self, data):
        """Preprocess input data for CLIP"""
        try:
            # Handle different input types
            if isinstance(data[0].get("data"), dict):
                # Image-text pair
                input_data = data[0].get("data")
                image_data = input_data.get("image")
                text_data = input_data.get("text", "")
                
                if isinstance(image_data, str):
                    # Base64 encoded image
                    image_bytes = base64.b64decode(image_data)
                    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
                else:
                    raise ValueError("Invalid image data format")
                
                # Process with CLIP processor
                inputs = self.processor(
                    text=text_data if text_data else None,
                    images=image,
                    return_tensors="pt",
                    padding=True
                )
                
                # Move to device
                inputs = {k: v.to(self.device) for k, v in inputs.items()}
                
                return {
                    "inputs": inputs,
                    "text": text_data,
                    "has_text": bool(text_data)
                }
            
            else:
                raise ValueError("Unsupported input format")
                
        except Exception as e:
            logger.error(f"Semantic preprocessing failed: {e}")
            raise
    
    def inference(self, data, *args, **kwargs):
        """Run CLIP inference for semantic analysis"""
        try:
            inputs = data["inputs"]
            has_text = data["has_text"]
            text = data["text"]
            
            with torch.no_grad():
                # Get embeddings
                outputs = self.model(**inputs)
                
                # Image embeddings
                image_embeddings = outputs.image_embeds.cpu().numpy().flatten()
                
                if has_text:
                    # Text embeddings
                    text_embeddings = outputs.text_embeds.cpu().numpy().flatten()
                    
                    # Calculate similarity
                    similarity = torch.nn.functional.cosine_similarity(
                        outputs.image_embeds, 
                        outputs.text_embeds
                    ).item()
                    
                    result = {
                        "image_embeddings": image_embeddings.tolist(),
                        "text_embeddings": text_embeddings.tolist(),
                        "semantic_similarity": float(similarity),
                        "has_text_input": True,
                        "text_input": text
                    }
                else:
                    # No text input - just return image embeddings
                    result = {
                        "image_embeddings": image_embeddings.tolist(),
                        "text_embeddings": None,
                        "semantic_similarity": None,
                        "has_text_input": False,
                        "text_input": None
                    }
                
                # Add metadata
                result.update({
                    "embedding_dimension": len(image_embeddings),
                    "model_version": "clip-vit-base-patch32"
                })
                
                return result
                
        except Exception as e:
            logger.error(f"Semantic inference failed: {e}")
            raise
    
    def postprocess(self, data):
        """Postprocess semantic analysis results"""
        try:
            result = {
                "semantic_analysis": {
                    "image_embeddings": data["image_embeddings"],
                    "text_embeddings": data["text_embeddings"],
                    "semantic_similarity": data["semantic_similarity"],
                    "embedding_dimension": data["embedding_dimension"],
                    "has_text_input": data["has_text_input"],
                    "text_input": data["text_input"],
                    "model_version": data["model_version"]
                }
            }
            
            return [json.dumps(result)]
            
        except Exception as e:
            logger.error(f"Semantic postprocessing failed: {e}")
            raise

# Required for TorchServe
_service = SemanticSimilarityHandler()


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
        logger.error(f"Semantic handler execution failed: {e}")
        return [json.dumps({"error": str(e)})]