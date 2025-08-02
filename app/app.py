import os

from flask import Flask
from flask_migrate import Migrate

from app.database import db
from app.routes import bp

migrate = Migrate()


def create_app():
    app = Flask(__name__)
    db_url = os.getenv('DATABASE_URL', 'sqlite:///hello_you.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = db_url
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    migrate.init_app(app, db)

    app.register_blueprint(bp)
    return app


if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
