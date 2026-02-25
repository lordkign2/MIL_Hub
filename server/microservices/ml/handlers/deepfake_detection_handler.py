import torch
import numpy as np
from PIL import Image
import io
import json
import base64
import logging
import cv2
from ts.torch_handler.base_handler import BaseHandler

logger = logging.getLogger(__name__)

class DeepfakeDetectionHandler(BaseHandler):
    """
    TorchServe handler for video deepfake detection
    """
    
    def __init__(self):
        super(DeepfakeDetectionHandler, self).__init__()
        self.initialized = False
        self.model = None
        self.device = None
        self.transform = None
        
    def initialize(self, context):
        """Initialize model and preprocessing"""
        try:
            logger.info("Initializing Deepfake Detection Handler")
            
            # Set device
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            logger.info(f"Using device: {self.device}")
            
            # Load model
            self.model = self._load_model()
            self.model.to(self.device)
            self.model.eval()
            
            # Define preprocessing transforms
            self.transform = self._get_transforms()
            
            self.initialized = True
            logger.info("Deepfake Detection Handler initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize handler: {e}")
            raise
    
    def _load_model(self):
        """Load the deepfake detection model"""
        # For production, load your trained Xception-based model
        import torchvision.models as models
        
        # Using Xception-like architecture (simplified)
        model = models.resnet18(pretrained=True)
        model.fc = torch.nn.Linear(model.fc.in_features, 2)  # Binary classification
        
        return model
    
    def _get_transforms(self):
        """Get video frame transforms"""
        return torch.nn.Sequential(
            torch.nn.AdaptiveAvgPool2d((224, 224)),
            torch.nn.Lambda(lambda x: x / 255.0),
            torch.nn.Normalize(mean=[0.485, 0.456, 0.406], 
                              std=[0.229, 0.224, 0.225])
        )
    
    def preprocess(self, data):
        """Preprocess video frames"""
        try:
            # Extract frames from input (assuming base64 encoded video)
            if isinstance(data[0].get("data"), str):
                video_data = base64.b64decode(data[0].get("data"))
            else:
                raise ValueError("Unsupported input format")
            
            # Extract frames (simplified - in production, use proper video processing)
            frames = self._extract_frames(video_data)
            
            # Process frames
            processed_frames = []
            for frame in frames:
                # Convert to tensor
                frame_tensor = torch.from_numpy(frame).permute(2, 0, 1).float()
                processed_frames.append(frame_tensor)
            
            # Stack frames
            frames_tensor = torch.stack(processed_frames)
            
            return frames_tensor.to(self.device)
            
        except Exception as e:
            logger.error(f"Video preprocessing failed: {e}")
            raise
    
    def _extract_frames(self, video_data):
        """Extract frames from video data"""
        # Simplified frame extraction - in production, use proper video processing
        # This is a placeholder that returns sample frames
        frames = []
        for i in range(10):  # Extract 10 sample frames
            # Create sample frame (in production, actually extract from video)
            frame = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)
            frames.append(frame)
        return frames
    
    def inference(self, data, *args, **kwargs):
        """Run deepfake detection inference"""
        try:
            frame_predictions = []
            
            # Process each frame
            with torch.no_grad():
                for frame in data:
                    frame = frame.unsqueeze(0)  # Add batch dimension
                    output = self.model(frame)
                    probabilities = torch.nn.functional.softmax(output, dim=1)
                    
                    # Store frame-level predictions
                    real_prob = float(probabilities[0][0].item())
                    fake_prob = float(probabilities[0][1].item())
                    frame_predictions.append({
                        'real': real_prob,
                        'fake': fake_prob,
                        'prediction': 'fake' if fake_prob > 0.5 else 'real'
                    })
            
            # Aggregate predictions
            avg_fake_prob = float(np.mean([pred['fake'] for pred in frame_predictions]))
            avg_real_prob = float(np.mean([pred['real'] for pred in frame_predictions]))
            
            # Temporal consistency (simplified)
            predictions = [pred['prediction'] for pred in frame_predictions]
            consistency_score = self._calculate_temporal_consistency(predictions)
            
            return {
                "frame_predictions": frame_predictions,
                "average_fake_probability": avg_fake_prob,
                "average_real_probability": avg_real_prob,
                "temporal_consistency": consistency_score,
                "overall_prediction": "fake" if avg_fake_prob > 0.5 else "real",
                "confidence": max(avg_fake_prob, avg_real_prob)
            }
                
        except Exception as e:
            logger.error(f"Deepfake inference failed: {e}")
            raise
    
    def _calculate_temporal_consistency(self, predictions):
        """Calculate temporal consistency between frames"""
        if len(predictions) < 2:
            return 1.0
        
        # Simple consistency measure: ratio of consistent consecutive predictions
        consistent_pairs = 0
        total_pairs = len(predictions) - 1
        
        for i in range(total_pairs):
            if predictions[i] == predictions[i + 1]:
                consistent_pairs += 1
        
        return consistent_pairs / total_pairs if total_pairs > 0 else 1.0
    
    def postprocess(self, data):
        """Postprocess deepfake detection results"""
        try:
            result = {
                "deepfake_detection": {
                    "is_deepfake": data["overall_prediction"] == "fake",
                    "fake_probability": data["average_fake_probability"],
                    "real_probability": data["average_real_probability"],
                    "confidence": data["confidence"],
                    "temporal_consistency": data["temporal_consistency"],
                    "frames_analyzed": len(data["frame_predictions"]),
                    "model_version": "1.0.0"
                }
            }
            
            return [json.dumps(result)]
            
        except Exception as e:
            logger.error(f"Deepfake postprocessing failed: {e}")
            raise

# Required for TorchServe
_service = DeepfakeDetectionHandler()


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
        logger.error(f"Deepfake handler execution failed: {e}")
        return [json.dumps({"error": str(e)})]