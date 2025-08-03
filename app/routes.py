from datetime import date

from flask import Blueprint, jsonify, abort
from flask import request

from app.database import db
from app.models import User
from app.validators import is_valid_username, validate_put_request, ValidationError

bp = Blueprint('routes', __name__)


@bp.before_app_request
def validate_username_before_request():
    """Global check for username safety on /hello endpoints."""
    path = request.path
    if path.startswith("/hello/"):
        # Extract username from path
        username = path.split("/hello/")[-1].split("/")[0]

        # Fail fast if invalid
        if not is_valid_username(username):
            abort(400, "Invalid username. Only letters are allowed.")


@bp.route('/hello/<username>', methods=['PUT'])
def put_user(username):
    data = request.get_json(silent=True)

    try:
        dob = validate_put_request(data, User)
    except ValidationError as e:
        abort(400, str(e))

    user = User.query.filter_by(username=username).first()
    if not user:
        user = User(username=username, date_of_birth=dob)
        db.session.add(user)
    else:
        user.date_of_birth = dob

    db.session.commit()
    return '', 204


@bp.route('/hello/<username>', methods=['GET'])
def get_user(username):
    """
    Retrieves a birthday message for the given user.
    - Returns 400 if user does not exist (to avoid username enumeration).
    - Global before_app_request already validates the username format.
    """
    user = User.query.filter_by(username=username).first()
    if not user:
        abort(400, "Bad request")  # hide whether user exists

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

    return jsonify({"message": message})


@bp.route('/health', methods=['GET'])
@bp.route('/', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200
