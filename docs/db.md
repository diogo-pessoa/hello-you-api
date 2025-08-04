# Database Schema

Simple database design for the Hello World Birthday API.  

see: [migrations](../migrations) for DB versions. 

## Users Table

| Column     | Type        | Constraints      | Description                    |
|------------|-------------|------------------|--------------------------------|
| id         | INTEGER     | PRIMARY KEY      | Auto-incrementing user ID      |
| username   | VARCHAR(50) | UNIQUE, NOT NULL | Username (letters only)        |
| birthdate  | DATE        | NOT NULL         | User's date of birth           |

## SQL Schema

To initialize DB.

```bash 
# DATABASE MIGRATIONS
	make db-init #Initialize migration folder
	make db-migrate #Create a new migration
	make makedb-upgrade
	make db-downgrade # Roll back last migration
```
reference: [Flask migrate](https://flask-migrate.readthedocs.io/en/latest/)

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    birthdate DATE NOT NULL
);
```

## SQLAlchemy (ORM) Model

[SQLAlchemy Docs](https://www.sqlalchemy.org/)
```python
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    birthdate = db.Column(db.Date, nullable=False)
```

## Business Rules

- **Username**: Only letters (a-z, A-Z), must be unique
- **Birth Date**: Must be in the past (before today)
- **Format**: Date format is YYYY-MM-DD

