from flask import Blueprint, request, jsonify, current_app
from models import db, User
from validators import is_valid_username, is_valid_date, days_until_birthday

# Create blueprint
api = Blueprint('api', __name__)


@api.route('/hello/<username>', methods=['PUT'])
def save_user(username):
    current_app.logger.info(f"PUT request for user: {username}")

    if not is_valid_username(username):
        current_app.logger.warning(f"Invalid username: {username}")
        return jsonify({'error': 'Username must contain only letters'}), 400

    data = request.get_json()
    if not data or 'dateOfBirth' not in data:
        current_app.logger.warning(f"Missing dateOfBirth for user: {username}")
        return jsonify({'error': 'dateOfBirth is required'}), 400

    valid, birth_date = is_valid_date(data['dateOfBirth'])
    if not valid:
        current_app.logger.warning(f"Invalid date for user {username}: {data['dateOfBirth']}")
        if birth_date is None:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        else:
            return jsonify({'error': 'Date must be before today'}), 400

    try:
        user = User.query.filter_by(username=username).first()
        if user:
            current_app.logger.info(f"Updating existing user: {username}")
            user.birthdate = birth_date
        else:
            current_app.logger.info(f"Creating new user: {username}")
            user = User(username=username, birthdate=birth_date)
            db.session.add(user)

        db.session.commit()
        current_app.logger.info(f"Successfully saved user: {username}")
        return '', 204

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Database error for user {username}: {str(e)}")
        return jsonify({'error': 'Database error'}), 500


@api.route('/hello/<username>', methods=['GET'])
def get_hello(username):
    current_app.logger.info(f"GET request for user: {username}")

    if not is_valid_username(username):
        current_app.logger.warning(f"Invalid username: {username}")
        return jsonify({'error': 'Username must contain only letters'}), 400

    user = User.query.filter_by(username=username).first()
    if not user:
        current_app.logger.warning(f"User not found: {username}")
        return jsonify({'error': 'User not found'}), 404

    days = days_until_birthday(user.birthdate)
    if days == 0:
        message = f"Hello, {username}! Happy birthday!"
        current_app.logger.info(f"Birthday today for user: {username}")
    else:
        message = f"Hello, {username}! Your birthday is in {days} day(s)"
        current_app.logger.info(f"Birthday in {days} days for user: {username}")

    return jsonify({'message': message}), 200


@api.route('/health', methods=['GET'])
def health():
    current_app.logger.debug("Health check requested")
    return jsonify({'status': 'healthy'}), 200