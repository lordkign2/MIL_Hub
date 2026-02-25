# Security Configuration

import os
import hashlib
from cryptography.fernet import Fernet
from datetime import datetime, timedelta

class SecurityManager:
    def __init__(self):
        # Load encryption key from environment or generate new one
        key = os.getenv('ENCRYPTION_KEY')
        if not key:
            key = Fernet.generate_key().decode()
            print(f"Generated new encryption key: {key}")
        self.cipher = Fernet(key.encode())
        
    def encrypt_data(self, data: str) -> str:
        """Encrypt sensitive data"""
        return self.cipher.encrypt(data.encode()).decode()
    
    def decrypt_data(self, encrypted_data: str) -> str:
        """Decrypt sensitive data"""
        return self.cipher.decrypt(encrypted_data.encode()).decode()
    
    def hash_file_content(self, file_path: str) -> str:
        """Create SHA-256 hash of file content for integrity checking"""
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    
    def validate_file_type(self, file_path: str, allowed_types: list) -> bool:
        """Validate file type using magic numbers"""
        import magic
        try:
            file_type = magic.from_file(file_path, mime=True)
            return file_type in allowed_types
        except Exception:
            return False
    
    def is_safe_filename(self, filename: str) -> bool:
        """Validate filename for security"""
        # Prevent directory traversal and special characters
        unsafe_patterns = ['../', '..\\', '/', '\\', '<', '>', ':', '"', '|', '?', '*']
        return not any(pattern in filename for pattern in unsafe_patterns)
    
    def generate_secure_token(self, length: int = 32) -> str:
        """Generate cryptographically secure random token"""
        return os.urandom(length).hex()
    
    def cleanup_expired_files(self, upload_dir: str, max_age_hours: int = 24):
        """Delete files older than specified age"""
        import shutil
        from pathlib import Path
        
        max_age = timedelta(hours=max_age_hours)
        current_time = datetime.now()
        
        upload_path = Path(upload_dir)
        if not upload_path.exists():
            return
            
        for file_path in upload_path.iterdir():
            if file_path.is_file():
                file_age = current_time - datetime.fromtimestamp(file_path.stat().st_mtime)
                if file_age > max_age:
                    try:
                        file_path.unlink()
                        print(f"Deleted expired file: {file_path}")
                    except Exception as e:
                        print(f"Failed to delete {file_path}: {e}")

# Rate limiting configuration
class RateLimiter:
    def __init__(self, redis_client):
        self.redis = redis_client
        
    def is_rate_limited(self, key: str, limit: int, window_seconds: int) -> bool:
        """Check if request should be rate limited"""
        current = self.redis.get(key)
        if current is None:
            self.redis.setex(key, window_seconds, 1)
            return False
            
        if int(current) >= limit:
            return True
            
        self.redis.incr(key)
        return False
    
    def get_limits(self) -> dict:
        """Return rate limiting configuration"""
        return {
            'api': {'limit': 60, 'window': 60},      # 60 requests per minute
            'upload': {'limit': 10, 'window': 60},    # 10 uploads per minute
            'heavy': {'limit': 30, 'window': 60},      # 30 heavy operations per minute
        }

# Security middleware for FastAPI
def security_middleware(app):
    """Add security headers to all responses"""
    @app.middleware("http")
    async def add_security_headers(request, call_next):
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        return response

# File validation rules
ALLOWED_FILE_TYPES = {
    'image': [
        'image/jpeg',
        'image/png', 
        'image/gif',
        'image/webp'
    ],
    'video': [
        'video/mp4',
        'video/quicktime',
        'video/x-msvideo',
        'video/webm'
    ],
    'audio': [
        'audio/mpeg',
        'audio/wav',
        'audio/ogg',
        'audio/aac'
    ]
}

MAX_FILE_SIZES = {
    'image': 20 * 1024 * 1024,    # 20MB
    'video': 100 * 1024 * 1024,   # 100MB
    'audio': 50 * 1024 * 1024     # 50MB
}