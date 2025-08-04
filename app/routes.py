from datetime import date

from flask import Blueprint, jsonify, abort, request, current_app

from app.database import db
from app.models import User
from app.validators import is_valid_username, validate_put_request, ValidationError

bp = Blueprint('routes', __name__)


@bp.before_app_request
def validate_username_before_request():
    """Global check for username safety on /hello endpoints."""
    path = request.path
    if path.startswith("/hello/"):
        username = path.split("/hello/")[-1].split("/")[0]
        if not is_valid_username(username):
            current_app.logger.warning("Rejected invalid username: %s", username)
            abort(400, "Invalid username. Only letters are allowed.")


@bp.route('/hello/<username>', methods=['PUT'])
def put_user(username):
    current_app.logger.info("Received PUT request for user: %s", username)
    data = request.get_json(silent=True)

    try:
        dob = validate_put_request(data, User)
        current_app.logger.debug("Validated date of birth for %s: %s", username, dob)
    except ValidationError as e:
        current_app.logger.warning("Validation failed for %s: %s", username, str(e))
        abort(400, str(e))

    try:
        user = User.query.filter_by(username=username).first()
        if not user:
            user = User(username=username, date_of_birth=dob)
            db.session.add(user)
            status_code = 201
            headers = {"Location": f"/hello/{username}"}
            current_app.logger.info("Created new user: %s", username)
        else:
            user.date_of_birth = dob
            status_code = 204
            headers = {}
            current_app.logger.info("Updated existing user: %s", username)

        db.session.commit()
        return '', status_code, headers
    except Exception as e:
        db.session.rollback()
        current_app.logger.error("Failed to save user %s: %s", username, str(e))
        abort(500, "Internal server error")


@bp.route('/hello/<username>', methods=['GET'])
def get_user(username):
    current_app.logger.info("Received GET request for user: %s", username)
    try:
        user = User.query.filter_by(username=username).first()
    except Exception as e:
        current_app.logger.error("Database error fetching user %s: %s", username, str(e))
        abort(500, "Internal server error")

    if not user:
        current_app.logger.warning("User %s not found", username)
        abort(400, "Bad request")

    today = date.today()
    next_birthday = user.date_of_birth.replace(year=today.year)
    if next_birthday < today:
        next_birthday = next_birthday.replace(year=today.year + 1)

    days_until = (next_birthday - today).days
    message = (
        f"Hello, {username}! Happy birthday!"
        if days_until == 0
        else f"Hello, {username}! Your birthday is in {days_until} day(s)"
    )

    current_app.logger.debug("Birthday message for %s: %s", username, message)
    return jsonify({"message": message})



@bp.route('/users', methods=['GET'])
def get_all_users():
    current_app.logger.info("Received GET request for all users")
    try:
        users = User.query.all()
        result = [
            {"username": user.username, "date_of_birth": user.date_of_birth.isoformat()}
            for user in users
        ]
        current_app.logger.info("Fetched %d users", len(result))
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error("Error fetching all users: %s", str(e))
        abort(500, "Internal server error")


@bp.route('/health', methods=['GET'])
@bp.route('/', methods=['GET'])
def health():
    current_app.logger.debug("Health check endpoint hit")
    return jsonify({"status": "healthy"}), 200
