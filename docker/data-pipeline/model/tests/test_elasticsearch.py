"""The definitions on the stack are the files, and the analyzers / pipelines behave as documented."""
import json
import unittest

from support import ENTITIES, ES_DIR, StackTestCase, es, load_json, mapping

META = load_json(ES_DIR / "auto_apply_metadata.json")
CUSTOMERS = ENTITIES["customer"]["index"]


def tokens(analyzer, text, kind="analyzer"):
    return [t["token"] for t in es("POST", f"/{CUSTOMERS}/_analyze", {kind: analyzer, "text": text})["tokens"]]


def simulate(pipeline, doc):
    result = es("POST", f"/_ingest/pipeline/{pipeline}/_simulate", {"docs": [{"_source": doc}]})
    return result["docs"][0]["doc"]["_source"]


class DeployedDefinitionsTest(StackTestCase):
    def test_indices_use_the_file_mapping(self):
        for entity, e in ENTITIES.items():
            with self.subTest(index=e["index"]):
                live = es("GET", f"/{e['index']}/_mapping")[e["index"]]["mappings"]
                expected = mapping(entity)
                self.assertEqual(live["properties"], expected["properties"])
                self.assertEqual(live.get("_meta"), expected["_meta"])
                settings = es("GET", f"/{e['index']}/_settings")[e["index"]]["settings"]["index"]
                self.assertEqual(settings["default_pipeline"], e["pipeline"])
                self.assertIn("name_index_analyzer", settings["analysis"]["analyzer"])

    def test_pipelines_are_the_files(self):
        for p in META["ingest_pipelines"]:
            with self.subTest(pipeline=p["name"]):
                live = es("GET", f"/_ingest/pipeline/{p['name']}")[p["name"]]
                self.assertEqual(live["processors"], load_json(ES_DIR / p["filename"])["processors"])

    def test_search_templates_are_the_files(self):
        for s in META["search_templates"]:
            with self.subTest(template=s["name"]):
                live = es("GET", f"/_scripts/{s['name']}")["script"]["source"]
                self.assertEqual(live, (ES_DIR / s["filename"]).read_text())

    def test_templates_render_valid_json(self):
        params = [{}, {"query": "x", "fuzzy": True, "broader": True, "phrase": "y", "ref": "r", "email": "e",
                       "phone": "1", "phone_last4": "1234", "status": "ACTIVE", "amount_currency": "EUR",
                       "amount_gte": 1, "amount_lte": 2, "registered_at_gte": "2025-01-01", "opened_lt": "2026-01-01"}]
        for s in META["search_templates"]:
            for p in params:
                with self.subTest(template=s["name"], params=sorted(p)):
                    rendered = es("POST", "/_render/template", {"id": s["name"], "params": p})["template_output"]
                    self.assertIn("query", rendered)


class AnalyzerTest(StackTestCase):
    def test_name_index_keeps_original_and_parts(self):
        self.assertEqual(tokens("name_index_analyzer", "Marie-Claire"), ["marie-claire", "marie", "claire"])
        self.assertEqual(tokens("name_index_analyzer", "D'Arcy"), ["d'arcy", "d", "arcy"])
        self.assertEqual(tokens("name_index_analyzer", "Zoë Müller"), ["zoe", "muller"])
        self.assertIn("dante", tokens("name_index_analyzer", "Dante's"))

    def test_company_suffixes_are_removed(self):
        self.assertEqual(tokens("company_search_analyzer", "GMBH Kestrel"), ["kestrel"])
        self.assertEqual(tokens("company_search_analyzer", "Ltd"), [])
        self.assertEqual(tokens("company_index_analyzer", "Fjord Fisheries AS"), ["fjord", "fisheries"])

    def test_prefixes_from_three_characters(self):
        grams = tokens("name_prefix_index_analyzer", "Alexandra")
        self.assertIn("ale", grams)
        self.assertIn("alexandra", grams)
        self.assertNotIn("al", grams)

    def test_email_fragments(self):
        self.assertEqual(tokens("email_text_analyzer", "kai_lee+invoices.2025@mailbox.example"),
                         ["kai", "lee", "invoices", "2025", "mailbox", "example"])

    def test_english(self):
        self.assertEqual(tokens("english_analyzer", "Refunds delayed while the audits are running"),
                         ["refund", "delai", "while", "audit", "run"])
        self.assertEqual(tokens("english_analyzer", "organ organs organic organization"),
                         ["organ", "organ", "organic", "organization"])

    def test_normalizers(self):
        self.assertEqual(tokens("phone_normalizer", "+61 (2) 9374-4000", "normalizer"), ["61293744000"])
        self.assertEqual(tokens("phone_normalizer", "(800) 555‑2100", "normalizer"), ["8005552100"])
        self.assertEqual(tokens("phone_last4_normalizer", "+44 161 496 0123", "normalizer"), ["0123"])
        self.assertEqual(tokens("lowercase_normalizer", "Ola.Nordmann@Example.NO", "normalizer"), ["ola.nordmann@example.no"])


class PipelineTest(StackTestCase):
    def test_customer_status_label(self):
        for code, label in [(0, "PENDING"), (1, "ACTIVE"), (3, "CLOSED"), (9, "UNKNOWN")]:
            with self.subTest(code=code):
                doc = simulate("customers-cdc", {"id": 1, "first_name": "A", "last_name": "B", "status": code, "__op": "c",
                                                 "registered_at": 1746660600000000, "__ts_ms": 1746660600000})
                self.assertEqual((doc["status"], doc["status_code"]), (label, code))
                self.assertEqual(doc["full_name"], "A B")
                self.assertEqual(doc["registered_at"], "2025-05-07T23:30:00Z")
                self.assertEqual(doc["cdc_op"], "c")
                self.assertNotIn("__ts_ms", doc)

    def test_contact_value_routed_by_kind(self):
        email = simulate("contacts-cdc", {"id": 1, "kind": "EMAIL", "value": "A@B.example"})
        phone = simulate("contacts-cdc", {"id": 2, "kind": "PHONE", "value": "+1 555"})
        self.assertEqual((email.get("email"), email.get("phone")), ("A@B.example", None))
        self.assertEqual((phone.get("phone"), phone.get("email")), ("+1 555", None))

    def test_account_credit(self):
        for base, credit, minor, amount, currency in [("EUR", None, 250000, 2500.0, "EUR"),
                                                      ("CNY", "JPY", 5000000, 5000000.0, "JPY"),
                                                      ("SEK", "EUR", 1000000, 10000.0, "EUR"),
                                                      ("KWD", None, 1500, 1.5, "KWD")]:
            with self.subTest(base=base, credit=credit):
                doc = simulate("accounts-cdc", {"id": 1, "base_currency": base, "credit_currency": credit,
                                                "credit_limit_minor": minor})
                self.assertEqual((doc["credit_limit"], doc["credit_currency"]), (amount, currency))
                self.assertNotIn("credit_limit_minor", doc)


if __name__ == "__main__":
    unittest.main()
