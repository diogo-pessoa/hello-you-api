FROM registry.access.redhat.com/ubi9/python-311:latest

WORKDIR /app

USER root

RUN dnf update -y && \
    dnf install -y postgresql-devel gcc python3-devel && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy entire app package
COPY app/ ./app/

RUN chown -R 1001:0 /app && \
    chmod 755 /app

USER 1001

EXPOSE 5000

ENV FLASK_ENV=production
ENV PORT=5000

# Run with gunicorn, using __init__.py's app instance
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
