"""Every Postgres row reached its index through Debezium + the ES sink, with the pipeline applied."""
import unittest

from support import ENTITIES, StackTestCase, es, sql_rows, wait_for_sync


class CdcSyncTest(StackTestCase):
    def test_every_row_is_a_document(self):
        for entity in ENTITIES:
            with self.subTest(entity=entity):
                ids, doc_ids = wait_for_sync(entity)
                self.assertTrue(ids, f"{ENTITIES[entity]['table']} is empty: run scripts/migrate.sh migrate")
                self.assertEqual(ids, doc_ids, "missing / extra documents")

    def test_customer_documents(self):
        rows = {r["id"]: r for r in sql_rows("SELECT id, customer_ref, first_name, last_name, status FROM inventory.customers")}
        labels = {0: "PENDING", 1: "ACTIVE", 2: "SUSPENDED", 3: "CLOSED"}
        for doc in self._docs("customer"):
            row = rows[doc["id"]]
            with self.subTest(ref=row["customer_ref"]):
                self.assertEqual(doc["customer_ref"], row["customer_ref"])
                self.assertEqual(doc["full_name"], f"{row['first_name']} {row['last_name']}")
                self.assertEqual(doc["status"], labels.get(row["status"], "UNKNOWN"))

    def test_account_documents(self):
        rows = {r["id"]: r for r in sql_rows(
            "SELECT id, account_ref, base_currency, COALESCE(credit_currency, base_currency) AS cur, credit_limit_minor FROM inventory.accounts")}
        for doc in self._docs("account"):
            row = rows[doc["id"]]
            with self.subTest(ref=row["account_ref"]):
                self.assertEqual(doc["credit_currency"], row["cur"])
                exponent = 0 if row["cur"] in ("JPY", "KRW") else 2
                self.assertAlmostEqual(doc["credit_limit"], row["credit_limit_minor"] / 10 ** exponent)

    def test_contact_documents(self):
        rows = {r["id"]: r for r in sql_rows("SELECT id, kind, value FROM inventory.contacts")}
        for doc in self._docs("contact"):
            row = rows[doc["id"]]
            with self.subTest(value=row["value"]):
                self.assertEqual(doc["email" if row["kind"] == "EMAIL" else "phone"], row["value"])

    @staticmethod
    def _docs(entity):
        hits = es("POST", f"/{ENTITIES[entity]['index']}/_search", {"size": 1000})["hits"]["hits"]
        return [h["_source"] for h in hits]


if __name__ == "__main__":
    unittest.main()
