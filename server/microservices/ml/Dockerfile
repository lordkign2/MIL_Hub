FROM pytorch/torchserve:0.9.1-gpu

# Set working directory
WORKDIR /home/model-server

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model files
COPY models/ /home/model-server/models/
COPY handlers/ /home/model-server/handlers/
COPY config/ /home/model-server/config/

# Create model store directory
RUN mkdir -p /home/model-server/model-store

# Expose TorchServe ports
EXPOSE 8080 8081 8082

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ping || exit 1

# Run TorchServe
CMD ["torchserve", "--start", "--model-store", "model-store", "--models", "all"]