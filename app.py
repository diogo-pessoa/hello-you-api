from flask import Flask
import os

# Import our modules
from models import db, User
from routes import api
from config import Config
from metrics import init_metrics

# Create Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Initialize logging
Config.init_logging(app)

# Initialize database with app
db.init_app(app)

# Register blueprint
app.register_blueprint(api)

# Initialize Prometheus metrics - this connects everything
metrics_instance = init_metrics(app)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()

    port = int(os.environ.get('PORT', 5000))

    # Disable debug mode for metrics to work properly
    # See: https://github.com/rycus86/prometheus_flask_exporter/issues/40
    debug_mode = os.environ.get('FLASK_ENV') == 'development' and os.environ.get('ENABLE_FLASK_DEBUG',
                                                                                 'false').lower() == 'true'
    # /metrics returns 404 if debug set to True
    # https://github.com/rycus86/prometheus_flask_exporter/issues/40
    app.run(host='0.0.0.0', debug=debug_mode, port=port)


