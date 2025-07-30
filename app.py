import os

from flask import Flask

from config import Config
from models import db
from routes import api

app = Flask(__name__)
app.config.from_object(Config)

# Initialize logging
Config.init_logging(app)

# Initialize database with app
db.init_app(app)

# Register blueprint
app.register_blueprint(api)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()

    port = int(os.environ.get('PORT', 5000))
    # Bind to all interfaces for Docker
    app.run(host='0.0.0.0', debug=app.config['DEBUG'], port=port)
