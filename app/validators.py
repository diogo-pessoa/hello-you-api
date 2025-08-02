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
    elif this_year < today:
        next_year = birth_date.replace(year=today.year + 1)
        return (next_year - today).days
    else:
        return (this_year - today).days
