import cv2
import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import imagehash
from typing import Dict, List, Tuple, Optional
import logging
from pydantic import BaseModel
import timm
from transformers import CLIPProcessor, CLIPModel

logger = logging.getLogger(__name__)

class ImageAnalysisResult(BaseModel):
    perceptual_hash: str
    hash_vector: List[float]
    exif_data: Dict
    ai_generated_probability: float
    image_quality_score: float
    technical_metadata: Dict
    confidence: float

class ImageVerificationEngine:
    def __init__(self, device: str = 'cpu'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        logger.info(f"Image verification engine initialized on {self.device}")
        
        # Initialize models
        self._initialize_models()
        self._initialize_transforms()
        
    def _initialize_models(self):
        """Initialize all required models"""
        try:
            # Load EfficientNet for AI detection
            self.efficientnet = timm.create_model('efficientnet_b0', pretrained=True)
            self.efficientnet.eval()
            self.efficientnet.to(self.device)
            
            # Load CLIP model for semantic analysis
            self.clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
            self.clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
            self.clip_model.eval()
            self.clip_model.to(self.device)
            
            logger.info("AI models loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load models: {e}")
            raise
    
    def _initialize_transforms(self):
        """Initialize image transforms"""
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                               std=[0.229, 0.224, 0.225])
        ])
        
        self.clip_transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor()
        ])
    
    def extract_perceptual_hash(self, image_path: str) -> Tuple[str, List[float]]:
        """Extract perceptual hash and convert to vector"""
        try:
            # Load image
            image = Image.open(image_path)
            
            # Generate perceptual hash
            phash = imagehash.phash(image)
            phash_str = str(phash)
            
            # Convert hash to vector (64-dimensional)
            hash_vector = [float(bit) for bit in ''.join(format(int(char, 16), '04b') 
                                                        for char in phash_str)]
            
            return phash_str, hash_vector
            
        except Exception as e:
            logger.error(f"Perceptual hash extraction failed: {e}")
            raise
    
    def extract_exif_data(self, image_path: str) -> Dict:
        """Extract EXIF metadata from image"""
        try:
            image = Image.open(image_path)
            exif_data = {}
            
            if hasattr(image, '_getexif') and image._getexif():
                exif = image._getexif()
                for tag_id, value in exif.items():
                    tag = TAGS.get(tag_id, tag_id)
                    exif_data[tag] = value
            
            # Basic image info
            exif_data.update({
                'width': image.width,
                'height': image.height,
                'mode': image.mode,
                'format': image.format
            })
            
            return exif_data
            
        except Exception as e:
            logger.error(f"EXIF extraction failed: {e}")
            return {}
    
    def detect_ai_generated(self, image_path: str) -> float:
        """Detect if image is AI-generated using EfficientNet"""
        try:
            # Load and preprocess image
            image = Image.open(image_path).convert('RGB')
            input_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            # Get model prediction
            with torch.no_grad():
                output = self.efficientnet(input_tensor)
                probabilities = torch.nn.functional.softmax(output[0], dim=0)
                
                # Use the maximum probability as AI detection score
                # In production, you'd use a specialized AI detection model
                ai_score = float(torch.max(probabilities).item())
                
            return ai_score
            
        except Exception as e:
            logger.error(f"AI detection failed: {e}")
            return 0.5  # Neutral score on error
    
    def analyze_image_quality(self, image_path: str) -> float:
        """Analyze image quality metrics"""
        try:
            # Load image using OpenCV
            image = cv2.imread(image_path)
            if image is None:
                return 0.0
            
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Calculate blur using Laplacian variance
            blur_score = cv2.Laplacian(gray, cv2.CV_64F).var()
            
            # Calculate contrast
            contrast = gray.std()
            
            # Calculate brightness
            brightness = gray.mean()
            
            # Normalize scores (0-1 range)
            blur_normalized = min(blur_score / 1000.0, 1.0)
            contrast_normalized = min(contrast / 100.0, 1.0)
            brightness_normalized = 1.0 - abs(brightness - 128) / 128.0
            
            # Combined quality score
            quality_score = (blur_normalized + contrast_normalized + brightness_normalized) / 3.0
            
            return float(quality_score)
            
        except Exception as e:
            logger.error(f"Quality analysis failed: {e}")
            return 0.5
    
    def extract_clip_features(self, image_path: str) -> np.ndarray:
        """Extract CLIP embeddings for semantic analysis"""
        try:
            image = Image.open(image_path).convert('RGB')
            
            # Process with CLIP
            inputs = self.clip_processor(images=image, return_tensors="pt")
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            with torch.no_grad():
                image_features = self.clip_model.get_image_features(**inputs)
                embeddings = image_features.cpu().numpy().flatten()
            
            return embeddings
            
        except Exception as e:
            logger.error(f"CLIP feature extraction failed: {e}")
            return np.zeros(512)  # CLIP base model dimension
    
    def verify_image(self, image_path: str, media_id: str) -> ImageAnalysisResult:
        """Perform complete image verification analysis"""
        try:
            logger.info(f"Starting image verification for {media_id}")
            
            # Extract perceptual hash
            phash, hash_vector = self.extract_perceptual_hash(image_path)
            
            # Extract EXIF data
            exif_data = self.extract_exif_data(image_path)
            
            # Detect AI-generated content
            ai_probability = self.detect_ai_generated(image_path)
            
            # Analyze image quality
            quality_score = self.analyze_image_quality(image_path)
            
            # Extract semantic features
            clip_features = self.extract_clip_features(image_path)
            
            # Calculate overall confidence
            confidence = self._calculate_confidence(
                quality_score, 
                len(exif_data) > 0, 
                ai_probability
            )
            
            result = ImageAnalysisResult(
                perceptual_hash=phash,
                hash_vector=hash_vector,
                exif_data=exif_data,
                ai_generated_probability=ai_probability,
                image_quality_score=quality_score,
                technical_metadata={
                    'clip_embedding_dim': len(clip_features),
                    'file_size': os.path.getsize(image_path),
                    'analysis_timestamp': datetime.utcnow().isoformat()
                },
                confidence=confidence
            )
            
            logger.info(f"Image verification completed for {media_id}")
            return result
            
        except Exception as e:
            logger.error(f"Image verification failed for {media_id}: {e}")
            raise
    
    def _calculate_confidence(self, quality_score: float, has_exif: bool, ai_prob: float) -> float:
        """Calculate overall confidence score"""
        # Weighted confidence calculation
        quality_weight = 0.4
        exif_weight = 0.3
        ai_weight = 0.3
        
        exif_score = 1.0 if has_exif else 0.5
        ai_score = 1.0 - abs(ai_prob - 0.5) * 2  # Neutral is 0.5
        
        confidence = (
            quality_score * quality_weight +
            exif_score * exif_weight +
            ai_score * ai_weight
        )
        
        return min(max(confidence, 0.0), 1.0)

# Import required for EXIF tags
from PIL.ExifTags import TAGS
from datetime import datetime