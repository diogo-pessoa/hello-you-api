import unittest
from datetime import date, timedelta

from app.validators import is_valid_username, is_valid_date, days_until_birthday


class TestValidationFunctions(unittest.TestCase):

    def test_is_valid_username_valid(self):
        self.assertTrue(is_valid_username("John"))
        self.assertTrue(is_valid_username("Alice"))

    def test_is_valid_username_invalid(self):
        self.assertFalse(is_valid_username("John123"))
        self.assertFalse(is_valid_username("John_Doe"))
        self.assertFalse(is_valid_username(""))

    def test_is_valid_date_valid(self):
        past_date = (date.today() - timedelta(days=365)).strftime('%Y-%m-%d')
        result, birth_date = is_valid_date(past_date)
        self.assertTrue(result)
        self.assertEqual(birth_date, date.today() - timedelta(days=365))

    def test_is_valid_date_future(self):
        future_date = (date.today() + timedelta(days=10)).strftime('%Y-%m-%d')
        result, birth_date = is_valid_date(future_date)
        self.assertFalse(result)
        self.assertEqual(birth_date, date.today() + timedelta(days=10))

    def test_is_valid_date_invalid_format(self):
        result, birth_date = is_valid_date("2020/01/01")
        self.assertFalse(result)
        self.assertIsNone(birth_date)

    def test_days_until_birthday_today(self):
        today = date.today()
        self.assertEqual(days_until_birthday(today), 0)

    def test_days_until_birthday_future_this_year(self):
        today = date.today()
        future_birthday = today + timedelta(days=30)
        self.assertEqual(days_until_birthday(future_birthday), 30)

    def test_days_until_birthday_next_year(self):
        today = date.today()
        past_birthday = today - timedelta(days=30)
        expected_days = (past_birthday.replace(year=today.year + 1) - today).days
        self.assertEqual(days_until_birthday(past_birthday), expected_days)


if __name__ == '__main__':
    unittest.main()
