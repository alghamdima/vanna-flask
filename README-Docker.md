# Docker Deployment Guide for Vanna Flask Application

## Quick Start

### 1. Environment Setup
Copy the example environment file and configure your credentials:
```bash
cp .env.example .env
# Edit .env with your actual credentials
```

### 2. Build and Run with Docker
```bash
# Build the Docker image
docker build -t vanna-flask:latest .

# Run the container
docker run -d \
  --name vanna-flask-app \
  -p 5000:5000 \
  --env-file .env \
  vanna-flask:latest
```

### 3. Using Docker Compose (Recommended)
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Production Deployment (Direct Flask Serving)

The application now serves directly through Flask without NGINX:
- Flask application serves on ports 80 (HTTP) and 443 (HTTPS)
- CORS enabled for cross-origin requests
- Health checks monitor the application directly
- Static files served by Flask

### Environment Variables
Required environment variables:
- `VANNA_MODEL`: Your Vanna.AI model name
- `VANNA_API_KEY`: Your Vanna.AI API key
- `SNOWFLAKE_ACCOUNT`: Snowflake account identifier
- `SNOWFLAKE_USERNAME`: Snowflake username
- `SNOWFLAKE_PASSWORD`: Snowflake password
- `SNOWFLAKE_DATABASE`: Snowflake database name
- `SNOWFLAKE_WAREHOUSE`: Snowflake warehouse name

### Health Checks
The application includes health checks that monitor:
- Application responsiveness on port 5000
- 30-second intervals with 10-second timeout
- 3 retries before marking as unhealthy

### Security Features
- Non-root user execution
- Minimal base image (Python slim)
- Security headers via Nginx
- No sensitive data in image layers
- Proper file permissions

## Monitoring and Maintenance

### View Application Logs
```bash
docker-compose logs -f vanna-flask
```

### Check Container Health
```bash
docker-compose ps
```

### Update Application
```bash
# Rebuild and restart
docker-compose build --no-cache
docker-compose up -d
```

### Backup and Restore
Since this application is stateless, no special backup procedures are needed for the application itself. Ensure your Vanna.AI and Snowflake credentials are securely backed up.

## Troubleshooting

### Common Issues
1. **Port already in use**: Change the port mapping in docker-compose.yml
2. **Environment variables not loaded**: Ensure .env file exists and is properly formatted
3. **Connection issues**: Verify Snowflake and Vanna.AI credentials
4. **Permission denied**: Ensure Docker daemon is running and user has proper permissions

### Debug Mode
To run in debug mode:
```bash
docker run -it --rm \
  --env-file .env \
  -e FLASK_DEBUG=True \
  -p 5000:5000 \
  vanna-flask:latest
```