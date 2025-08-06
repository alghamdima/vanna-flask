# Multi-stage build for Python Flask application
# Stage 1: Builder stage for installing dependencies
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies needed for building Python packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy dependency files first for better layer caching
COPY requirements.txt .

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Production stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application files
COPY app.py .
COPY cache.py .
COPY requirements.txt .
COPY static/ ./static/

# Create non-root user for security
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home --shell /bin/bash appuser

# Change ownership of application files
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 5000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Set environment variables for production
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Start the application
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000"]

# Labels for documentation
LABEL maintainer="Vanna.AI Team"
LABEL version="1.0.0"
LABEL description="Production-ready Docker image for Vanna Flask application"
LABEL org.opencontainers.image.source="https://github.com/vanna-ai/vanna-flask"
LABEL org.opencontainers.image.title="Vanna Flask App"
LABEL org.opencontainers.image.description="Web server for chatting with your database using Vanna.AI"