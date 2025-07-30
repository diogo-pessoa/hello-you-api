import pytest
import json
from datetime import date, timedelta
from app import app
from models import db, User


@pytest.fixture
def client():
    # Configure for testing
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'

    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()


def test_health_endpoint(client):
    """Test health check"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'


def test_save_user_valid(client):
    """Test saving a user with valid data"""
    yesterday = (date.today() - timedelta(days=1)).strftime('%Y-%m-%d')

    response = client.put('/hello/john',
                          data=json.dumps({'dateOfBirth': yesterday}),
                          content_type='application/json')

    assert response.status_code == 204


def test_get_user_message(client):
    """Test getting user message"""
    # First save a user
    yesterday = (date.today() - timedelta(days=1)).strftime('%Y-%m-%d')
    client.put('/hello/jane',
               data=json.dumps({'dateOfBirth': yesterday}),
               content_type='application/json')

    # Then get the message
    response = client.get('/hello/jane')
    assert response.status_code == 200

    data = json.loads(response.data)
    assert 'Hello, jane!' in data['message']


def test_invalid_username(client):
    """Test invalid username"""
    yesterday = (date.today() - timedelta(days=1)).strftime('%Y-%m-%d')

    response = client.put('/hello/john123',
                          data=json.dumps({'dateOfBirth': yesterday}),
                          content_type='application/json')

    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'Username must contain only letters' in data['error']


def test_user_not_found(client):
    """Test getting non-existent user"""
    response = client.get('/hello/nobody')
    assert response.status_code == 404

    data = json.loads(response.data)
    assert 'User not found' in data['error']