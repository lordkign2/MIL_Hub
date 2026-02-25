from celery import shared_task
import logging
import os
from datetime import datetime
from typing import Dict, Any
from .image_analysis import ImageVerificationEngine

logger = logging.getLogger(__name__)

@shared_task(bind=True, name='image_tasks.verify_image')
def verify_image_task(self, media_id: str, file_path: str, user_id: str) -> Dict[str, Any]:
    """Celery task for image verification"""
    try:
        logger.info(f"Starting image verification task for media_id: {media_id}")
        
        # Initialize verification engine
        device = os.getenv('ML_DEVICE', 'cpu')
        engine = ImageVerificationEngine(device=device)
        
        # Perform verification
        result = engine.verify_image(file_path, media_id)
        
        # Prepare response
        response = {
            'media_id': media_id,
            'user_id': user_id,
            'task_id': self.request.id,
            'status': 'completed',
            'result': result.dict(),
            'completed_at': datetime.utcnow().isoformat(),
            'processing_time_seconds': self.request.task_info.get('runtime', 0) if hasattr(self.request, 'task_info') else 0
        }
        
        logger.info(f"Image verification completed for {media_id}")
        return response
        
    except Exception as e:
        logger.error(f"Image verification failed for {media_id}: {e}")
        return {
            'media_id': media_id,
            'user_id': user_id,
            'task_id': self.request.id,
            'status': 'failed',
            'error': str(e),
            'completed_at': datetime.utcnow().isoformat()
        }

@shared_task(bind=True, name='image_tasks.batch_verify')
def batch_verify_images(self, media_list: list) -> Dict[str, Any]:
    """Batch verification of multiple images"""
    try:
        logger.info(f"Starting batch verification for {len(media_list)} images")
        
        results = []
        failed_count = 0
        
        for media_item in media_list:
            try:
                result = verify_image_task(
                    media_item['media_id'],
                    media_item['file_path'],
                    media_item['user_id']
                )
                results.append(result)
            except Exception as e:
                failed_count += 1
                logger.error(f"Batch item failed: {e}")
        
        response = {
            'total_processed': len(media_list),
            'successful': len(results) - failed_count,
            'failed': failed_count,
            'results': results,
            'completed_at': datetime.utcnow().isoformat()
        }
        
        logger.info(f"Batch verification completed: {response}")
        return response
        
    except Exception as e:
        logger.error(f"Batch verification failed: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'completed_at': datetime.utcnow().isoformat()
        }

@shared_task(name='image_tasks.cleanup_processed_files')
def cleanup_processed_files(file_paths: list, retention_hours: int = 24):
    """Cleanup processed image files"""
    try:
        import time
        current_time = time.time()
        deleted_count = 0
        
        for file_path in file_paths:
            try:
                if os.path.exists(file_path):
                    file_age = current_time - os.path.getctime(file_path)
                    if file_age > (retention_hours * 3600):
                        os.remove(file_path)
                        deleted_count += 1
                        logger.info(f"Deleted processed file: {file_path}")
            except Exception as e:
                logger.error(f"Failed to delete {file_path}: {e}")
        
        return {
            'deleted_files': deleted_count,
            'total_files': len(file_paths),
            'completed_at': datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Cleanup failed: {e}")
        return {'status': 'failed', 'error': str(e)}