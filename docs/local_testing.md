# Local Testing Guide

This guide covers how to run and understand the test suite for the Hello World Birthday API.

## Test Overview

The application uses **pytest** for testing with the following coverage:
- ✅ **85% overall code coverage**
- ✅ API endpoint testing (PUT/GET requests)
- ✅ Input validation testing
- ✅ Error handling scenarios
- ✅ Integration testing (save + retrieve flow)

## Running Tests

### Basic Test Execution
```bash
# Run all tests with verbose output
make test

# Or manually:
pytest test_app.py -v
```

### Test Coverage Report
```bash
# Run tests with coverage analysis
make test-cov

# This generates:
# - Terminal coverage report
# - HTML coverage report in htmlcov/
```

### Coverage Analysis
```bash
# View detailed HTML coverage report
open htmlcov/index.html

# Or view in browser:
# file://path/to/project/htmlcov/index.html
```

## Test Structure

### Test File Organization
```
test_app.py                 # Main test file
├── Fixtures
│   └── client()           # Test client with in-memory database
├── API Tests
│   ├── Health endpoint
│   ├── User creation (PUT)
│   ├── User retrieval (GET)
│   └── Error scenarios
└── Integration Tests
    └── Full save/retrieve flow
```

### Test Database
Tests use an **in-memory SQLite database** that is:
- Created fresh for each test
- Isolated between tests
- Automatically cleaned up
- Fast and lightweight

## Test Cases

### 1. Health Check Test
```python
def test_health_endpoint(client):
    """Test health check"""
    response = client.get('/health')
    assert response.status_code == 200
    assert data['status'] == 'healthy'
```

### 2. Valid User Creation
```python
def test_save_user_valid(client):
    """Test saving a user with valid data"""
    # Tests successful user creation with valid date
```

### 3. User Message Retrieval
```python
def test_get_user_message(client):
    """Test getting user message"""
    # Tests full flow: create user then get birthday message
```

### 4. Input Validation Tests
```python
def test_invalid_username(client):
    """Test invalid username"""
    # Tests username with numbers/special characters

def test_missing_date_of_birth(client):
    """Test missing dateOfBirth field"""
    # Tests API validation for required fields

def test_invalid_date_format(client):
    """Test invalid date format"""
    # Tests date validation (format and past date requirement)
```

### 5. Error Handling Tests
```python
def test_user_not_found(client):
    """Test getting non-existent user"""
    # Tests 404 response for missing users

def test_future_date(client):
    """Test future date of birth"""
    # Tests business rule: birth date must be in past
```

## Running Individual Tests

### Single Test Function
```bash
# Run specific test
pytest test_app.py::test_health_endpoint -v

# Run test with detailed output
pytest test_app.py::test_save_user_valid -v -s
```

### Test Categories
```bash
# Run tests matching pattern
pytest test_app.py -k "health" -v
pytest test_app.py -k "invalid" -v
pytest test_app.py -k "user" -v
```

## Understanding Test Output

### Successful Test Run
```
test_app.py::test_health_endpoint PASSED      [ 20%]
test_app.py::test_save_user_valid PASSED      [ 40%]
test_app.py::test_get_user_message PASSED     [ 60%]
test_app.py::test_invalid_username PASSED     [ 80%]
test_app.py::test_user_not_found PASSED       [100%]

========== 8 passed in 0.45s ==========
```

### Coverage Report
```
Name            Stmts   Miss  Cover   Missing
---------------------------------------------
app.py             15      4    73%   23-27
config.py          22      0   100%
models.py           6      0   100%
routes.py          56     16    71%   19-20, 24-28, 33-34
validators.py      19      4    79%   13-14, 22, 27
---------------------------------------------
TOTAL             159     24    85%
```

### Reading Coverage
- **Stmts**: Total lines of code
- **Miss**: Lines not covered by tests  
- **Cover**: Percentage covered
- **Missing**: Specific line numbers not tested

## Test Data Patterns

### Valid Test Data
```python
# Valid past date
yesterday = (date.today() - timedelta(days=1)).strftime('%Y-%m-%d')

# Valid username (letters only)
username = 'john'

# Valid request payload
{'dateOfBirth': '1990-01-01'}
```

### Invalid Test Data
```python
# Invalid usernames
'john123'    # Contains numbers
'user-name'  # Contains special characters

# Invalid dates
'invalid-date'        # Bad format
'2025-01-01'         # Future date
'1990-13-01'         # Invalid month
```

## Writing New Tests

### Test Function Template
```python
def test_new_feature(client):
    """Test description"""
    # Arrange: Set up test data
    test_data = {'key': 'value'}
    
    # Act: Make API call
    response = client.put('/hello/username', 
                         data=json.dumps(test_data),
                         content_type='application/json')
    
    # Assert: Check results
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'expected' in data
```

### Test Best Practices
1. **Descriptive names**: `test_invalid_username_with_numbers`
2. **Clear assertions**: Test one thing per test function
3. **Use fixtures**: Leverage the `client` fixture for API calls
4. **Test edge cases**: Invalid inputs, boundary conditions
5. **Test error scenarios**: 400, 404, 500 responses

## Debugging Failed Tests

### Verbose Output
```bash
# See detailed test output
pytest test_app.py -v -s

# See print statements in tests
pytest test_app.py -v -s --capture=no
```

### Failed Test Analysis
```bash
# Show local variables on failure
pytest test_app.py --tb=long

# Drop into debugger on failure
pytest test_app.py --pdb
```

### Common Test Failures

**1. Database state issues**
```python
# Ensure clean test isolation
with app.app_context():
    db.create_all()
    yield client
    db.drop_all()  # Important cleanup
```

**2. JSON serialization**
```python
# Always use json.dumps for request data
data=json.dumps({'dateOfBirth': date_str})
content_type='application/json'
```

**3. Date calculations**
```python
# Be careful with timezone-sensitive date calculations
from datetime import date, timedelta
yesterday = (date.today() - timedelta(days=1))
```

## Continuous Testing

### Watch Mode (Optional)
```bash
# Install pytest-watch
pip install pytest-watch

# Run tests automatically on file changes
ptw test_app.py
```

### Pre-commit Testing
```bash
# Add to git pre-commit hook
#!/bin/bash
make test || exit 1
```

## Next Steps

- Build and test Docker container: [Docker Guide](docker.md)
- Review database design: [Database Schema](db.md)
- Understand system architecture: [System Diagram](system_diagram.md)