from flask import Blueprint, request, jsonify, current_app
from models import db, User
from validators import is_valid_username, is_valid_date, days_until_birthday
import time

# Create blueprint
api = Blueprint('api', __name__)


@api.route('/hello/<username>', methods=['PUT'])
def save_user(username):
    # Import metrics here to avoid circular import issues
    from metrics import user_operations, request_duration, active_users

    start_time = time.time()
    current_app.logger.info(f"PUT request for user: {username}")

    if not is_valid_username(username):
        current_app.logger.warning(f"Invalid username: {username}")
        if user_operations:
            user_operations.labels(operation='create_user', status='invalid_username').inc()
        return jsonify({'error': 'Username must contain only letters'}), 400

    data = request.get_json()
    if not data or 'dateOfBirth' not in data:
        current_app.logger.warning(f"Missing dateOfBirth for user: {username}")
        if user_operations:
            user_operations.labels(operation='create_user', status='missing_data').inc()
        return jsonify({'error': 'dateOfBirth is required'}), 400

    valid, birth_date = is_valid_date(data['dateOfBirth'])
    if not valid:
        current_app.logger.warning(f"Invalid date for user {username}: {data['dateOfBirth']}")
        if user_operations:
            user_operations.labels(operation='create_user', status='invalid_date').inc()
        if birth_date is None:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        else:
            return jsonify({'error': 'Date must be before today'}), 400

    try:
        user = User.query.filter_by(username=username).first()
        if user:
            current_app.logger.info(f"Updating existing user: {username}")
            user.birthdate = birth_date
            if user_operations:
                user_operations.labels(operation='update_user', status='success').inc()
        else:
            current_app.logger.info(f"Creating new user: {username}")
            user = User(username=username, birthdate=birth_date)
            db.session.add(user)
            if user_operations:
                user_operations.labels(operation='create_user', status='success').inc()

        db.session.commit()

        # Update active users gauge
        total_users = User.query.count()
        if active_users:
            active_users.set(total_users)

        current_app.logger.info(f"Successfully saved user: {username}")

        # Record request duration
        duration = time.time() - start_time
        if request_duration:
            request_duration.labels(method='PUT', endpoint='/hello/<username>').observe(duration)

        return '', 204

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Database error for user {username}: {str(e)}")
        if user_operations:
            user_operations.labels(operation='create_user', status='database_error').inc()
        return jsonify({'error': 'Database error'}), 500


@api.route('/hello/<username>', methods=['GET'])
def get_hello(username):
    # Import metrics here to avoid circular import issues
    from metrics import user_operations, request_duration, birthday_calculations

    start_time = time.time()
    current_app.logger.info(f"GET request for user: {username}")

    if not is_valid_username(username):
        current_app.logger.warning(f"Invalid username: {username}")
        if user_operations:
            user_operations.labels(operation='get_message', status='invalid_username').inc()
        return jsonify({'error': 'Username must contain only letters'}), 400

    user = User.query.filter_by(username=username).first()
    if not user:
        current_app.logger.warning(f"User not found: {username}")
        if user_operations:
            user_operations.labels(operation='get_message', status='not_found').inc()
        return jsonify({'error': 'User not found'}), 404

    days = days_until_birthday(user.birthdate)

    # Record birthday calculation metrics
    if days == 0:
        if birthday_calculations:
            birthday_calculations.labels(days_until='today').inc()
        message = f"Hello, {username}! Happy birthday!"
        current_app.logger.info(f"Birthday today for user: {username}")
    else:
        if birthday_calculations:
            birthday_calculations.labels(days_until=str(days)).inc()
        message = f"Hello, {username}! Your birthday is in {days} day(s)"
        current_app.logger.info(f"Birthday in {days} days for user: {username}")

    if user_operations:
        user_operations.labels(operation='get_message', status='success').inc()

    # Record request duration
    duration = time.time() - start_time
    if request_duration:
        request_duration.labels(method='GET', endpoint='/hello/<username>').observe(duration)

    return jsonify({'message': message}), 200


@api.route('/health', methods=['GET'])
def health():
    current_app.logger.debug("Health check requested")
    return jsonify({'status': 'healthy'}), 200


@api.route('/debug-routes', methods=['GET'])
def debug_routes():
    """Debug endpoint to see all registered routes"""
    routes = []
    for rule in current_app.url_map.iter_rules():
        routes.append({
            'endpoint': rule.endpoint,
            'methods': list(rule.methods),
            'path': str(rule)
        })
    return jsonify({'routes': routes})