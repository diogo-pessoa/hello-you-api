import logging
import os

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # From .env file
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///helloworld.db')
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key')
    DEBUG = os.environ.get('FLASK_ENV') == 'development'

    # Logging configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()

    @staticmethod
    def init_logging(app):
        """Initialize structured logging"""
        log_level = getattr(logging, Config.LOG_LEVEL)

        # Create formatter for structured logs (JSON-like)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )

        # Configure app logger
        app.logger.setLevel(log_level)

        # Remove default handlers
        app.logger.handlers.clear()

        # Add console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        console_handler.setFormatter(formatter)
        app.logger.addHandler(console_handler)

        #  Avoid duplicate
        app.logger.propagate = False

        app.logger.info(f"Logging initialized at {Config.LOG_LEVEL} level")
