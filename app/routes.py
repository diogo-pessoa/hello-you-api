from flask import Blueprint, request, jsonify, abort
from database import db
from models import User
from datetime import datetime, date

bp = Blueprint('routes', __name__)

@bp.route('/hello/<username>', methods=['PUT'])
def put_user(username):
    if not User.validate_username(username):
        abort(400, "Invalid username. Only letters allowed.")

    data = request.get_json()
    try:
        dob = datetime.strptime(data['dateOfBirth'], '%Y-%m-%d').date()
    except ValueError:
        abort(400, "Invalid date format. Use YYYY-MM-DD.")

    if not User.validate_date(dob):
        abort(400, "Date of birth must be before today.")

    user = User.query.get(username)
    if not user:
        user = User(username=username, date_of_birth=dob)
        db.session.add(user)
    else:
        user.date_of_birth = dob

    db.session.commit()
    return '', 204


@bp.route('/hello/<username>', methods=['GET'])
def get_user(username):
    user = User.query.get(username)
    if not user:
        abort(404, "User not found.")

    today = date.today()
    next_birthday = user.date_of_birth.replace(year=today.year)
    if next_birthday < today:
        next_birthday = next_birthday.replace(year=today.year + 1)

    days_until = (next_birthday - today).days

    if days_until == 0:
        message = f"Hello, {username}! Happy birthday!"
    else:
        message = f"Hello, {username}! Your birthday is in {days_until} day(s)"

    return jsonify({"message": message})


@bp.route('/health', methods=['GET'])
@bp.route('/', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200
