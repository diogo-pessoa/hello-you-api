from database import db
from datetime import date
import re

class User(db.Model):
    __tablename__ = 'users'

    username = db.Column(db.String(50), primary_key=True)
    date_of_birth = db.Column(db.Date, nullable=False)

    @staticmethod
    def validate_username(username):
        return re.match(r'^[A-Za-z]+$', username) is not None

    @staticmethod
    def validate_date(date_of_birth):
        return date_of_birth < date.today()
