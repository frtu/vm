"""contacts-lookup on contacts_connect: lookup (full value) vs discovery (fragment, last 4 digits).
A hit is keyed `<customer_ref>:<value>`, the context a user needs to tell equal fragments apart.
Data: migration/V12 (basic) and V22 (variants)."""
import unittest

from support import SearchTestCase, sql_rows


class ContactSearchTest(SearchTestCase):
    entity = "contact"
    refs = {}

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.refs = {r["id"]: r["customer_ref"] for r in sql_rows("SELECT id, customer_ref FROM inventory.customers")}

    @classmethod
    def key(cls, source):
        return f"{cls.refs.get(source['customer_id'])}:{source['value']}"

    def test_email_lookup(self):
        self.run_cases([
            ("lowercased", {"email": "OLA.NORDMANN@example.no"}, {"cus_ono2212:Ola.Nordmann@Example.NO": "email_exact"}, [], True),
            ("joined local part", {"email": "olanordmann@example.no"}, {}, [], True),
            ("+tag is part of the address", {"email": "kai_lee@mailbox.example"}, {}, [], True),
            ("full address with +tag", {"email": "kai_lee+invoices.2025@mailbox.example"},
             {"cus_kle2502:kai_lee+invoices.2025@mailbox.example": "email_exact"}, [], True),
        ])

    def test_email_fragments(self):
        self.run_cases([
            ("domain words", {"query": "northwind traders"}, {"cus_ape2309:a.petrova@northwind-traders.example": "email_fragment"}, [], True),
            ("local part", {"query": "petrova"}, {"cus_ape2309:a.petrova@northwind-traders.example": "email_fragment"}, [], True),
            ("joined domain", {"query": "northwindtraders"}, {}, [], True),
            ("no typo", {"query": "nortwind"}, {}, [], True),
        ])

    def test_phone_lookup(self):
        self.run_cases([
            ("dots", {"phone": "415.555.0123"}, {"cus_ape2309:(415) 555-0123": "phone_exact"}, [], True),
            ("no spaces", {"phone": "(415)5550123"}, {"cus_ape2309:(415) 555-0123": "phone_exact"}, [], True),
            ("partial number", {"phone": "555-0123"}, {}, [], True),
            ("country code with brackets", {"phone": "+61 (2) 9374-4000"}, {"cus_kle2502:+61 2 9374 4000": "phone_exact"}, [], True),
            ("national trunk prefix", {"phone": "02 9374 4000"}, {}, [], True),
            # the same number belongs to two customers: both are returned, with their customer
            ("shared number", {"phone": "800 555 2100"},
             {"cus_bth2302:(800) 555‑2100": "phone_exact", "cus_sda2302:(800) 555‑2100": "phone_exact"}, [], True),
        ])

    def test_last_four_digits(self):
        self.run_cases([
            ("every match", {"phone_last4": "0123"},
             {"cus_ape2309:(415) 555-0123": "phone_last4", "cus_sli2408:+44 161 496 0123": "phone_last4"}, [], True),
            ("formatting of the query", {"phone_last4": "01-23"},
             {"cus_ape2309:(415) 555-0123": None, "cus_sli2408:+44 161 496 0123": None}, [], True),
        ])

    def test_filters(self):
        self.run_cases([
            ("kind + label", {"kind": "EMAIL", "label": "BILLING"}, {"cus_kle2502:kai_lee+invoices.2025@mailbox.example": None}, [], True),
            ("phones of one customer, preferred first", {"kind": "PHONE", "customer_id": self._id("cus_sda2302")},
             {"cus_sda2302:(800) 555‑2100": None, "cus_sda2302:(800) 555‑2200": None, "cus_sda2302:(800) 555‑2300": None}, [], True),
        ])
        hits = __import__("support").search(self.entity, {"kind": "PHONE", "customer_id": self._id("cus_sda2302")}, self.key)
        self.assertTrue(hits[0][2]["preferred"])

    def _id(self, ref):
        return next(i for i, r in self.refs.items() if r == ref)


if __name__ == "__main__":
    unittest.main()
