from datetime import datetime, timedelta

import pytest

from app.app import create_app
from app.database import db


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    with app.app_context():
        db.create_all()
        yield app.test_client()


def test_put_and_get_user_success(client):
    response = client.put('/hello/john', json={"dateOfBirth": "1990-05-10"})
    assert response.status_code == 204

    response = client.get('/hello/john')
    assert response.status_code == 200
    assert "Hello, john!" in response.json["message"]


@pytest.mark.parametrize("username", ["john123", "john_doe", "", "!@#"])
def test_put_invalid_username(client, username):
    response = client.put(f'/hello/{username}', json={"dateOfBirth": "1990-05-10"})
    assert response.status_code == 400
    assert "Invalid username" in response.json["error"]


def test_put_future_date(client):
    future_date = (datetime.today() + timedelta(days=1)).strftime("%Y-%m-%d")
    response = client.put('/hello/jane', json={"dateOfBirth": future_date})
    assert response.status_code == 400
    assert "before today" in response.json["error"]


@pytest.mark.parametrize("payload,error_message", [
    (None, "Missing required field"),
    ({}, "Missing required field"),
    ({"invalidKey": "2000-01-01"}, "Missing required field"),
    ({"dateOfBirth": 12345}, "must be a string"),
    ({"dateOfBirth": "2000/01/01"}, "Invalid date format"),
])
def test_put_invalid_payloads(client, payload, error_message):
    response = client.put('/hello/john', json=payload)
    assert response.status_code == 400
    assert error_message in response.json["error"]


def test_put_with_unexpected_field(client):
    payload = {"dateOfBirth": "1990-05-10", "extra": "bad"}
    response = client.put('/hello/john', json=payload)
    assert response.status_code == 400
    assert "Unexpected fields" in response.json["error"]


def test_get_invalid_username(client):
    response = client.get('/hello/john123')
    assert response.status_code == 400
    assert "Invalid username" in response.json["error"]


def test_get_nonexistent_user_returns_400(client):
    response = client.get('/hello/ghost')
    assert response.status_code == 400
    assert "Bad request" in response.json["error"]


def test_missing_endpoint_returns_empty_json(client):
    response = client.get('/nonexistent-endpoint')
    assert response.status_code == 404
    assert response.json == {}

def test_get_happy_birthday_message(client):
    today = datetime.today()
    dob = today.replace(year=today.year - 20).strftime("%Y-%m-%d")  # 20 years ago, same month/day
    client.put('/hello/alice', json={"dateOfBirth": dob})

    response = client.get('/hello/alice')
    assert response.status_code == 200
    assert "Happy birthday" in response.json["message"]


def test_put_update_existing_user(client):
    # Create
    client.put('/hello/alice', json={"dateOfBirth": "1990-05-10"})
    # Update
    response = client.put('/hello/alice', json={"dateOfBirth": "1991-05-10"})
    assert response.status_code == 204
