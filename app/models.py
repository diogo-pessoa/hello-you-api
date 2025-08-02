import re
from datetime import date

from app.database import db


class User(db.Model):
    __tablename__ = 'users'

    username = db.Column(db.String(50), primary_key=True)
    date_of_birth = db.Column(db.Date, nullable=False)

    @staticmethod
    def validate_username(username: str) -> bool:
        return re.match(r'^[A-Za-z]+$', username) is not None

    @staticmethod
    def validate_date(date_of_birth: date) -> bool:
        return date_of_birth < date.today()
