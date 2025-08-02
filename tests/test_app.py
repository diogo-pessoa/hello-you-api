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


def test_put_and_get_user(client):
    response = client.put('/hello/john', json={"dateOfBirth": "1990-05-10"})
    assert response.status_code == 204

    response = client.get('/hello/john')
    assert response.status_code == 200
    assert "Hello, john!" in response.json["message"]


def test_invalid_username(client):
    response = client.put('/hello/john123', json={"dateOfBirth": "1990-05-10"})
    assert response.status_code == 400


def test_future_date(client):
    response = client.put('/hello/jane', json={"dateOfBirth": "2999-01-01"})
    assert response.status_code == 400
