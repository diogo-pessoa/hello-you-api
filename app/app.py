# pylint: disable=unused-argument,invalid-envvar-default,redefined-outer-name
import os

from flask import Flask, jsonify
from flask_migrate import Migrate
from werkzeug.exceptions import HTTPException

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

    # --- Global Error Handlers ---
    @app.errorhandler(404)
    def handle_not_found(e):
        return jsonify({}), 404

    @app.errorhandler(HTTPException)
    def handle_http_exception(e):
        return jsonify({"error": e.description, "code": e.code}), e.code

    @app.errorhandler(Exception)
    def handle_generic_exception(e):
        return jsonify({"error": "An unexpected error occurred", "code": 500}), 500

    return app


if __name__ == '__main__':
    app = create_app()

    # Run db.create_all() only in development mode
    if os.getenv('FLASK_ENV') == 'development':
        with app.app_context():
            db.create_all()
            app.logger.info("Database tables created automatically for development.")

    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
