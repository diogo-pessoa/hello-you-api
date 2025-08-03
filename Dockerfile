FROM registry.access.redhat.com/ubi9/python-311:latest

WORKDIR /app

USER root

# Install system dependencies for PostgreSQL and build tools
RUN dnf update -y && \
    dnf install -y postgresql-devel gcc python3-devel && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Copy Python requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy migrations and app code
COPY migrations/ ./migrations/
COPY app/ ./app/

# Set permissions for non-root user
RUN chown -R 1001:0 /app && \
    chmod 755 /app

USER 1001

EXPOSE 5000

# Environment variables
ENV FLASK_ENV=production
ENV PORT=5000

# Run migrations, then start Gunicorn with Flask app
CMD ["sh", "-c", "flask db upgrade && gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 60 --access-logfile - --error-logfile - app:app"]
