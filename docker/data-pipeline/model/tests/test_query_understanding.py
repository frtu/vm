"""catalog/query_understanding.py: user words -> listed value, amount or date. No stack needed."""
import unittest

import support  # noqa: F401 - puts catalog/ on sys.path
from query_understanding import edit_distance, understand


class EditDistanceTest(unittest.TestCase):
    def test_distances(self):
        for a, b, d in [("suspnded", "suspended", 1), ("kowalsky", "kowalski", 1), ("kovalsky", "kowalski", 2),
                        ("okaofr", "okafor", 1), ("meridain", "meridian", 1), ("lu", "li", 1)]:
            with self.subTest(a=a, b=b):
                self.assertEqual(edit_distance(a, b), d)


class FixedListTest(unittest.TestCase):
    cases = [
        ("account", "status", "Active", {"status": "resolved", "value": "ACTIVE"}),
        ("account", "status", "frozen", {"status": "resolved", "value": "SUSPENDED", "via": "curated wording"}),
        ("account", "status", "suspnded", {"status": "suggested", "choices": ["SUSPENDED"]}),
        ("account", "status", "dormant", {"status": "ambiguous", "choices": ["SUSPENDED", "CLOSED"]}),
        ("account", "status", "archived", {"status": "invalid"}),
        ("account", "base_currency", "nok", {"status": "resolved", "value": "NOK"}),
        ("account", "base_currency", "Swedish  Krona", {"status": "resolved", "value": "SEK"}),
        ("account", "base_currency", "yen", {"status": "resolved", "value": "JPY", "via": "curated wording"}),
        ("account", "base_currency", "krone", {"status": "ambiguous", "choices": ["DKK", "NOK"]}),
        ("account", "base_currency", "bitcoin", {"status": "invalid"}),
        ("account", "credit_currency", "euro", {"status": "resolved", "value": "EUR"}),
        ("customer", "status", "live", {"status": "resolved", "value": "ACTIVE"}),
        ("customer", "country_code", "norge", {"status": "resolved", "value": "NO"}),
        ("customer", "country_code", "scandinavia", {"status": "ambiguous", "choices": ["NO", "SE"]}),
        ("contact", "label", "cell", {"status": "resolved", "value": "MOBILE"}),
        ("contact", "kind", "telephone", {"status": "resolved", "value": "PHONE"}),
    ]

    def test_cases(self):
        for entity, field, text, expected in self.cases:
            with self.subTest(entity=entity, field=field, text=text):
                got = understand(entity, field, text)
                self.assertEqual({k: got.get(k) for k in expected}, expected, got)

    def test_never_the_nearest_code(self):
        # 2 edits from NOK: invalid, not NOK
        self.assertEqual(understand("account", "base_currency", "nkk")["status"], "suggested")
        self.assertEqual(understand("account", "base_currency", "nxx")["status"], "invalid")


class AmountTest(unittest.TestCase):
    def test_amounts(self):
        for text, expected in [
            ("2,500.00 EUR", {"status": "resolved", "amount": 2500.0, "currency": "EUR"}),
            ("5,000,000 jpy", {"status": "resolved", "amount": 5000000.0, "currency": "JPY"}),
            ("2500", {"status": "needs_currency", "amount": 2500.0}),
            ("2.500,00 EUR", {"status": "invalid"}),
            ("250 XYZ", {"status": "invalid_currency"}),
        ]:
            with self.subTest(text=text):
                got = understand("account", "amount", text)
                self.assertEqual({k: got.get(k) for k in expected}, expected, got)


class DateTest(unittest.TestCase):
    def test_dates(self):
        for text, expected in [
            ("05/07/2025", {"status": "ambiguous", "choices": ["2025-05-07 (MM/DD)", "2025-07-05 (DD/MM)"]}),
            ("25/07/2025", {"status": "resolved", "gte": "2025-07-25", "via": "only valid as DD/MM"}),
            ("07/07/2025", {"status": "resolved", "gte": "2025-07-07"}),
            ("2025-05-07", {"status": "resolved", "gte": "2025-05-07", "lt": "2025-05-08"}),
            ("31/31/2025", {"status": "invalid"}),
        ]:
            with self.subTest(text=text):
                got = understand("customer", "date", text)
                self.assertEqual({k: got.get(k) for k in expected}, expected, got)


if __name__ == "__main__":
    unittest.main()
