#!/usr/bin/env python3
"""
Model Management Script for TorchServe
"""

import os
import json
import subprocess
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

class ModelManager:
    def __init__(self, model_store_path: str = "model-store"):
        self.model_store = Path(model_store_path)
        self.model_store.mkdir(exist_ok=True)
        self.config_dir = Path("config")
        self.handlers_dir = Path("handlers")
        self.models_dir = Path("models")
        
    def create_model_archive(self, model_name: str, handler_file: str, 
                            model_file: str = None, version: str = "1.0"):
        """Create TorchServe model archive"""
        try:
            # Check if handler exists
            handler_path = self.handlers_dir / handler_file
            if not handler_path.exists():
                raise FileNotFoundError(f"Handler file not found: {handler_path}")
            
            # Build archive command
            cmd = [
                "torch-model-archiver",
                "--model-name", model_name,
                "--version", version,
                "--handler", str(handler_path),
                "--export-path", str(self.model_store)
            ]
            
            # Add model file if specified
            if model_file:
                model_path = self.models_dir / model_file
                if model_path.exists():
                    cmd.extend(["--model-file", str(model_path)])
                else:
                    logger.warning(f"Model file not found: {model_path}")
            
            # Add extra files
            extra_files = [str(self.config_dir / f"{model_name}_model_config.json")]
            if os.path.exists("requirements.txt"):
                extra_files.append("requirements.txt")
            
            cmd.extend(["--extra-files", ",".join(extra_files)])
            
            # Create archive
            logger.info(f"Creating model archive for {model_name}")
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Model archive created successfully: {result.stdout}")
            
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to create model archive: {e.stderr}")
            return False
        except Exception as e:
            logger.error(f"Model archive creation failed: {e}")
            return False
    
    def register_models(self):
        """Register all configured models"""
        try:
            models_config = [
                {
                    "name": "ai_detection",
                    "handler": "ai_detection_handler.py",
                    "model_file": None,
                    "config": "ai_detection_model_config.json"
                },
                {
                    "name": "deepfake_detection", 
                    "handler": "deepfake_detection_handler.py",
                    "model_file": None,
                    "config": "deepfake_detection_model_config.json"
                },
                {
                    "name": "semantic_similarity",
                    "handler": "semantic_similarity_handler.py",
                    "model_file": None,
                    "config": "semantic_similarity_model_config.json"
                }
            ]
            
            success_count = 0
            for model_config in models_config:
                if self.create_model_archive(
                    model_config["name"],
                    model_config["handler"],
                    model_config["model_file"]
                ):
                    success_count += 1
                    logger.info(f"Registered model: {model_config['name']}")
                else:
                    logger.error(f"Failed to register model: {model_config['name']}")
            
            logger.info(f"Model registration completed: {success_count}/{len(models_config)} successful")
            return success_count == len(models_config)
            
        except Exception as e:
            logger.error(f"Model registration failed: {e}")
            return False
    
    def start_torchserve(self, config_file: str = None):
        """Start TorchServe with registered models"""
        try:
            cmd = [
                "torchserve",
                "--start",
                "--model-store", str(self.model_store)
            ]
            
            if config_file:
                cmd.extend(["--ts-config", config_file])
            
            # Add all models
            model_archives = list(self.model_store.glob("*.mar"))
            if model_archives:
                model_list = [str(archive) for archive in model_archives]
                cmd.extend(["--models", ",".join(model_list)])
            
            logger.info("Starting TorchServe...")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("TorchServe started successfully")
                return True
            else:
                logger.error(f"TorchServe failed to start: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to start TorchServe: {e}")
            return False
    
    def stop_torchserve(self):
        """Stop TorchServe"""
        try:
            cmd = ["torchserve", "--stop"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("TorchServe stopped successfully")
                return True
            else:
                logger.error(f"Failed to stop TorchServe: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to stop TorchServe: {e}")
            return False
    
    def health_check(self):
        """Check if TorchServe is running and healthy"""
        try:
            import requests
            response = requests.get("http://localhost:8080/ping", timeout=5)
            return response.status_code == 200
        except Exception:
            return False

def main():
    """Main function to set up ML infrastructure"""
    logging.basicConfig(level=logging.INFO)
    
    manager = ModelManager()
    
    # Register all models
    logger.info("=== Setting up ML Model Infrastructure ===")
    
    if manager.register_models():
        logger.info("Model registration successful!")
        
        # Start TorchServe
        if manager.start_torchserve():
            logger.info("TorchServe started successfully!")
            
            # Health check
            if manager.health_check():
                logger.info("ML infrastructure is ready and healthy!")
                logger.info("Available endpoints:")
                logger.info("- AI Detection: http://localhost:8080/predictions/ai_detection")
                logger.info("- Deepfake Detection: http://localhost:8080/predictions/deepfake_detection") 
                logger.info("- Semantic Similarity: http://localhost:8080/predictions/semantic_similarity")
            else:
                logger.error("TorchServe health check failed")
        else:
            logger.error("Failed to start TorchServe")
    else:
        logger.error("Model registration failed")

if __name__ == "__main__":
    main()