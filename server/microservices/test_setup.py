#!/usr/bin/env python3
"""
Test script to verify the microservice setup
"""

import sys
import os
import subprocess
from pathlib import Path

def check_docker():
    """Check if Docker is installed and running"""
    try:
        result = subprocess.run(['docker', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✓ Docker: {result.stdout.strip()}")
        
        result = subprocess.run(['docker-compose', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✓ Docker Compose: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("✗ Docker or Docker Compose not found")
        return False

def check_directory_structure():
    """Verify directory structure"""
    required_dirs = [
        'server/microservices',
        'server/microservices/api_gateway',
        'server/microservices/orchestrator',
        'server/microservices/database',
        'server/microservices/services',
        'server/microservices/ml',
        'server/microservices/scoring'
    ]
    
    missing_dirs = []
    for dir_path in required_dirs:
        if not Path(dir_path).exists():
            missing_dirs.append(dir_path)
    
    if missing_dirs:
        print(f"✗ Missing directories: {missing_dirs}")
        return False
    else:
        print("✓ Directory structure verified")
        return True

def check_required_files():
    """Check for required configuration files"""
    required_files = [
        'server/microservices/docker-compose.yml',
        'server/microservices/requirements.txt',
        'server/microservices/.env.example',
        'server/microservices/orchestrator/main.py',
        'server/microservices/database/init/01_schema.sql'
    ]
    
    missing_files = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing_files.append(file_path)
    
    if missing_files:
        print(f"✗ Missing files: {missing_files}")
        return False
    else:
        print("✓ Required files present")
        return True

def main():
    """Main test function"""
    print("=== MIL Hub Microservice Setup Verification ===\n")
    
    checks = [
        ("Docker Environment", check_docker),
        ("Directory Structure", check_directory_structure),
        ("Required Files", check_required_files)
    ]
    
    all_passed = True
    for check_name, check_func in checks:
        print(f"Checking {check_name}...")
        if not check_func():
            all_passed = False
        print()
    
    if all_passed:
        print("🎉 All checks passed! Your microservice setup is ready.")
        print("\nNext steps:")
        print("1. Copy .env.example to .env and configure your settings")
        print("2. Run: docker-compose up --build")
        print("3. Access the API at http://localhost:8080")
    else:
        print("❌ Some checks failed. Please fix the issues above.")
        sys.exit(1)

if __name__ == "__main__":
    main()