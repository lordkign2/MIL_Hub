import os
import logging
import cv2
import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms
import mediapipe as mp
from PIL import Image
import ffmpeg
from typing import Dict, List, Tuple, Optional
import logging
from pydantic import BaseModel
import timm

logger = logging.getLogger(__name__)

class VideoAnalysisResult(BaseModel):
    frame_count: int
    duration_seconds: float
    fps: float
    resolution: Dict[str, int]
    deepfake_probability: float
    audio_deepfake_probability: float
    temporal_consistency_score: float
    visual_quality_score: float
    face_detection_results: List[Dict]
    frame_analysis_data: List[Dict]
    technical_metadata: Dict
    confidence: float

class VideoVerificationEngine:
    def __init__(self, device: str = 'cpu'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        logger.info(f"Video verification engine initialized on {self.device}")
        
        # Initialize MediaPipe
        self.mp_face_detection = mp.solutions.face_detection
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_detection = self.mp_face_detection.FaceDetection(
            model_selection=1, 
            min_detection_confidence=0.5
        )
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=10,
            refine_landmarks=True,
            min_detection_confidence=0.5
        )
        
        # Initialize models
        self._initialize_models()
        self._initialize_transforms()
    
    def _initialize_models(self):
        """Initialize deepfake detection models"""
        try:
            # Xception-based model for deepfake detection (simplified)
            self.xception_model = timm.create_model('xception', pretrained=True)
            self.xception_model.eval()
            self.xception_model.to(self.device)
            
            logger.info("Video analysis models loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load video models: {e}")
            raise
    
    def _initialize_transforms(self):
        """Initialize video transforms"""
        self.frame_transform = transforms.Compose([
            transforms.Resize((299, 299)),  # Xception input size
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
        ])
    
    def extract_video_metadata(self, video_path: str) -> Dict:
        """Extract basic video metadata"""
        try:
            # Use ffmpeg to get video info
            probe = ffmpeg.probe(video_path)
            video_stream = next((stream for stream in probe['streams'] 
                               if stream['codec_type'] == 'video'), None)
            
            if not video_stream:
                raise ValueError("No video stream found")
            
            return {
                'duration': float(probe['format']['duration']),
                'bit_rate': int(probe['format']['bit_rate']),
                'width': int(video_stream['width']),
                'height': int(video_stream['height']),
                'fps': eval(video_stream['avg_frame_rate']),
                'codec': video_stream['codec_name'],
                'frame_count': int(video_stream.get('nb_frames', 0))
            }
        except Exception as e:
            logger.error(f"Metadata extraction failed: {e}")
            return {}
    
    def extract_frames(self, video_path: str, frame_interval: int = 3) -> List[np.ndarray]:
        """Extract frames from video at regular intervals"""
        try:
            frames = []
            cap = cv2.VideoCapture(video_path)
            
            frame_count = 0
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break
                
                if frame_count % (frame_interval * int(cap.get(cv2.CAP_PROP_FPS))) == 0:
                    # Convert BGR to RGB
                    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    frames.append(frame_rgb)
                
                frame_count += 1
            
            cap.release()
            return frames
            
        except Exception as e:
            logger.error(f"Frame extraction failed: {e}")
            return []
    
    def analyze_frame_deepfake(self, frame: np.ndarray) -> float:
        """Analyze individual frame for deepfake indicators"""
        try:
            # Convert to PIL Image
            pil_image = Image.fromarray(frame)
            tensor = self.frame_transform(pil_image).unsqueeze(0).to(self.device)
            
            with torch.no_grad():
                output = self.xception_model(tensor)
                # Simple classification (in production, use proper deepfake detection model)
                probabilities = torch.nn.functional.softmax(output[0], dim=0)
                fake_score = float(probabilities[1].item())  # Assuming index 1 is fake
            
            return fake_score
            
        except Exception as e:
            logger.error(f"Frame analysis failed: {e}")
            return 0.5
    
    def analyze_face_landmarks(self, frame: np.ndarray) -> Dict:
        """Analyze facial landmarks and detect anomalies"""
        try:
            # Convert to RGB for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Face detection
            detection_results = self.face_detection.process(rgb_frame)
            face_detections = []
            
            if detection_results.detections:
                for detection in detection_results.detections:
                    bbox = detection.location_data.relative_bounding_box
                    face_detections.append({
                        'bbox': {
                            'xmin': bbox.xmin,
                            'ymin': bbox.ymin,
                            'width': bbox.width,
                            'height': bbox.height
                        },
                        'confidence': detection.score[0]
                    })
            
            # Face mesh analysis
            mesh_results = self.face_mesh.process(rgb_frame)
            facial_landmarks = []
            
            if mesh_results.multi_face_landmarks:
                for face_landmarks in mesh_results.multi_face_landmarks:
                    landmarks = []
                    for landmark in face_landmarks.landmark:
                        landmarks.append({
                            'x': landmark.x,
                            'y': landmark.y,
                            'z': landmark.z
                        })
                    facial_landmarks.append(landmarks)
            
            return {
                'faces_detected': len(face_detections),
                'face_detections': face_detections,
                'facial_landmarks': facial_landmarks,
                'landmarks_found': len(facial_landmarks) > 0
            }
            
        except Exception as e:
            logger.error(f"Face analysis failed: {e}")
            return {}
    
    def analyze_temporal_consistency(self, frame_features: List[Dict]) -> float:
        """Analyze temporal consistency between frames"""
        try:
            if len(frame_features) < 2:
                return 0.5
            
            # Calculate feature differences between consecutive frames
            differences = []
            for i in range(1, len(frame_features)):
                # Compare face detection counts
                prev_faces = frame_features[i-1].get('faces_detected', 0)
                curr_faces = frame_features[i].get('faces_detected', 0)
                
                # Simple consistency measure
                if prev_faces == curr_faces:
                    differences.append(1.0)
                else:
                    differences.append(1.0 - abs(prev_faces - curr_faces) / max(prev_faces, curr_faces, 1))
            
            return float(np.mean(differences)) if differences else 0.5
            
        except Exception as e:
            logger.error(f"Temporal analysis failed: {e}")
            return 0.5
    
    def analyze_video_quality(self, frames: List[np.ndarray]) -> float:
        """Analyze overall video quality"""
        try:
            if not frames:
                return 0.0
            
            quality_scores = []
            
            for frame in frames:
                gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
                
                # Sharpness (Laplacian variance)
                sharpness = cv2.Laplacian(gray, cv2.CV_64F).var()
                sharpness_normalized = min(sharpness / 1000.0, 1.0)
                
                # Contrast
                contrast = gray.std()
                contrast_normalized = min(contrast / 100.0, 1.0)
                
                # Brightness
                brightness = gray.mean()
                brightness_normalized = 1.0 - abs(brightness - 128) / 128.0
                
                # Combined quality
                quality = (sharpness_normalized + contrast_normalized + brightness_normalized) / 3.0
                quality_scores.append(quality)
            
            return float(np.mean(quality_scores)) if quality_scores else 0.5
            
        except Exception as e:
            logger.error(f"Quality analysis failed: {e}")
            return 0.5
    
    def verify_video(self, video_path: str, media_id: str) -> VideoAnalysisResult:
        """Perform complete video verification analysis"""
        try:
            logger.info(f"Starting video verification for {media_id}")
            
            # Extract metadata
            metadata = self.extract_video_metadata(video_path)
            
            # Extract frames (every 3 seconds)
            frames = self.extract_frames(video_path, frame_interval=3)
            
            if not frames:
                raise ValueError("No frames extracted from video")
            
            # Analyze each frame
            frame_analysis_data = []
            face_detection_results = []
            
            for i, frame in enumerate(frames):
                # Deepfake analysis
                deepfake_score = self.analyze_frame_deepfake(frame)
                
                # Face analysis
                face_data = self.analyze_face_landmarks(frame)
                face_detection_results.append(face_data)
                
                frame_analysis_data.append({
                    'frame_index': i,
                    'deepfake_score': deepfake_score,
                    'faces_detected': face_data.get('faces_detected', 0),
                    'timestamp': i * 3  # 3 seconds per frame
                })
            
            # Temporal consistency analysis
            temporal_score = self.analyze_temporal_consistency(face_detection_results)
            
            # Video quality analysis
            quality_score = self.analyze_video_quality(frames)
            
            # Calculate average deepfake probability
            avg_deepfake = float(np.mean([f['deepfake_score'] for f in frame_analysis_data]))
            
            # Calculate overall confidence
            confidence = self._calculate_confidence(
                quality_score,
                temporal_score,
                avg_deepfake,
                len(frames)
            )
            
            result = VideoAnalysisResult(
                frame_count=len(frames),
                duration_seconds=metadata.get('duration', 0.0),
                fps=metadata.get('fps', 0.0),
                resolution={
                    'width': metadata.get('width', 0),
                    'height': metadata.get('height', 0)
                },
                deepfake_probability=avg_deepfake,
                audio_deepfake_probability=0.5,  # Placeholder for audio analysis
                temporal_consistency_score=temporal_score,
                visual_quality_score=quality_score,
                face_detection_results=face_detection_results,
                frame_analysis_data=frame_analysis_data,
                technical_metadata={
                    'codec': metadata.get('codec', 'unknown'),
                    'bit_rate': metadata.get('bit_rate', 0),
                    'total_frames_analyzed': len(frames),
                    'analysis_timestamp': datetime.utcnow().isoformat()
                },
                confidence=confidence
            )
            
            logger.info(f"Video verification completed for {media_id}")
            return result
            
        except Exception as e:
            logger.error(f"Video verification failed for {media_id}: {e}")
            raise
    
    def _calculate_confidence(self, quality: float, temporal: float, deepfake: float, frame_count: int) -> float:
        """Calculate overall confidence score"""
        # Weighted confidence calculation
        quality_weight = 0.3
        temporal_weight = 0.3
        deepfake_weight = 0.2
        frame_weight = 0.2
        
        # Frame count factor (more frames = higher confidence)
        frame_factor = min(frame_count / 10.0, 1.0)  # Normalize to 10 frames
        
        confidence = (
            quality * quality_weight +
            temporal * temporal_weight +
            (1.0 - abs(deepfake - 0.5) * 2) * deepfake_weight +  # Neutral is 0.5
            frame_factor * frame_weight
        )
        
        return min(max(confidence, 0.0), 1.0)

from datetime import datetime