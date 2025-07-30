# Use Red Hat UBI Python hardened base image (no shell)
FROM registry.access.redhat.com/ubi9/python-311:latest

# Set working directory
WORKDIR /app

# Switch to root to install dependencies and setup user
USER root

# Install system dependencies for PostgreSQL
RUN dnf update -y && \
    dnf install -y postgresql-devel gcc python3-devel && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# The UBI Python image already has a user with UID 1001, so we'll use a different UID
# Or we can just use the existing default user (1001) which is already created
# Let's check what user exists and use it
RUN id 1001 || echo "User 1001 does not exist"

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies as root
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py models.py routes.py validators.py config.py ./

# Create directory for SQLite database and set permissions for UID 1001
RUN mkdir -p /app/data && \
    chown -R 1001:0 /app && \
    chmod 755 /app

# Switch to the existing non-root user (UID 1001)
USER 1001

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Set environment variables
ENV FLASK_ENV=production
ENV DATABASE_URL=sqlite:///data/helloworld.db
ENV PORT=5000

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "app:app"]