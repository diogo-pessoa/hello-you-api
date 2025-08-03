from datetime import date, timedelta, datetime

import pytest

from app.models import User
from app.validators import (
    is_valid_username,
    is_valid_date,
    days_until_birthday,
    validate_put_request,
    ValidationError
)


# Username validation tests
@pytest.mark.parametrize("username,expected", [
    ("John", True),
    ("Alice", True),
    ("John123", False),
    ("John_Doe", False),
    ("", False),
])
def test_is_valid_username(username, expected):
    assert is_valid_username(username) == expected


# Date validation tests
def test_is_valid_date_valid():
    past_date = (date.today() - timedelta(days=365)).strftime('%Y-%m-%d')
    result, birth_date = is_valid_date(past_date)
    assert result
    assert birth_date == date.today() - timedelta(days=365)


def test_is_valid_date_future():
    future_date = (date.today() + timedelta(days=10)).strftime('%Y-%m-%d')
    result, birth_date = is_valid_date(future_date)
    assert not result
    assert birth_date == date.today() + timedelta(days=10)


def test_is_valid_date_invalid_format():
    result, birth_date = is_valid_date("2020/01/01")
    assert not result
    assert birth_date is None


# Birthday calculation tests
def test_days_until_birthday_today():
    today = date.today()
    assert days_until_birthday(today) == 0


def test_days_until_birthday_future_this_year():
    today = date.today()
    future_birthday = today + timedelta(days=30)
    assert days_until_birthday(future_birthday) == 30


def test_days_until_birthday_next_year():
    today = date.today()
    past_birthday = today - timedelta(days=30)
    expected_days = (past_birthday.replace(year=today.year + 1) - today).days
    assert days_until_birthday(past_birthday) == expected_days


# PUT request validation tests

def test_valid_input_returns_date():
    valid_date = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
    data = {"dateOfBirth": valid_date}
    dob = validate_put_request(data, User)
    assert dob.strftime("%Y-%m-%d") == valid_date


@pytest.mark.parametrize("data,expected_message", [
    (None, "Missing required field: dateOfBirth."),
    ({}, "Missing required field: dateOfBirth."),
    ({"invalidKey": "2000-01-01"}, "Missing required field: dateOfBirth."),
    ({"dateOfBirth": 20000101}, "dateOfBirth must be a string in YYYY-MM-DD format."),
    ({"dateOfBirth": "2000/01/01"}, "Invalid date format. Use YYYY-MM-DD."),
    ({"dateOfBirth": (datetime.today() + timedelta(days=1)).strftime("%Y-%m-%d")},
     "Date of birth must be before today."),
])
def test_invalid_inputs_raise_error(data, expected_message):
    with pytest.raises(ValidationError) as exc_info:
        validate_put_request(data, User)
    assert expected_message in str(exc_info.value)


def test_unexpected_fields_raise_error():
    valid_date = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
    data = {"dateOfBirth": valid_date, "extraField": "oops"}
    with pytest.raises(ValidationError) as exc_info:
        validate_put_request(data, User)
    assert "Unexpected fields" in str(exc_info.value)
