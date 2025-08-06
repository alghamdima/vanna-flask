# Multi-stage build for Python Flask application with Vanna.AI integration
# Stage 1: Builder stage for installing dependencies and preparing the application
FROM python:3.11-slim as builder

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies required for building Python packages
# gcc and other build tools are needed for some Python packages like pandas, numpy
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements file first to leverage Docker layer caching
# If requirements.txt doesn't change, this layer will be cached
COPY requirements.txt .

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Stage 2: Production stage with minimal footprint
FROM python:3.11-slim as production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    FLASK_APP=app.py \
    FLASK_ENV=production

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY --chown=appuser:appuser . .

# Create directory for static files and ensure proper permissions
RUN mkdir -p /app/static && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the port that Flask runs on
EXPOSE 5000

# Add health check to monitor application status
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/v0/generate_questions || exit 1

# Add labels for better container management and documentation
LABEL maintainer="DevOps Team <devops@company.com>" \
      version="1.0.0" \
      description="Vanna.AI Flask application for database querying" \
      org.opencontainers.image.source="https://github.com/vanna-ai/vanna-flask" \
      org.opencontainers.image.documentation="https://github.com/vanna-ai/vanna-flask/blob/main/README.md" \
      org.opencontainers.image.vendor="Vanna.AI" \
      org.opencontainers.image.licenses="MIT"

# Use exec form for better signal handling
CMD ["python", "app.py"]