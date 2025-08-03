import re
from datetime import datetime, date


def is_valid_username(username):
    return re.match(r'^[a-zA-Z]+$', username) is not None


def is_valid_date(date_str):
    try:
        birth_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        return birth_date < date.today(), birth_date
    except ValueError:
        return False, None


def days_until_birthday(birth_date):
    today = date.today()
    this_year = birth_date.replace(year=today.year)

    if this_year == today:
        return 0
    if this_year < today:
        next_year = birth_date.replace(year=today.year + 1)
        return (next_year - today).days
    return (this_year - today).days


class ValidationError(Exception):
    """Custom exception for request validation errors."""


def validate_put_request(data, user_model):
    """
    Validates the PUT request body for user creation/update.
    Returns the parsed date of birth or raises ValidationError.
    """
    if not isinstance(data, dict) or 'dateOfBirth' not in data:
        raise ValidationError("Missing required field: dateOfBirth.")

    allowed_keys = {'dateOfBirth'}
    if set(data.keys()) - allowed_keys:
        raise ValidationError("Unexpected fields in request.")

    dob_str = data['dateOfBirth']
    if not isinstance(dob_str, str):
        raise ValidationError("dateOfBirth must be a string in YYYY-MM-DD format.")

    try:
        dob = datetime.strptime(dob_str, '%Y-%m-%d').date()
    except ValueError as exc:
        raise ValidationError("Invalid date format. Use YYYY-MM-DD.") from exc

    if not user_model.validate_date(dob):
        raise ValidationError("Date of birth must be before today.")

    return dob
