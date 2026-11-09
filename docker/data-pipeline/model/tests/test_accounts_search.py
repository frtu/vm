"""accounts-general on accounts_connect: one case per behavior of the account catalog.
Data: migration/V13 (basic) and V23 (variants)."""
import unittest

from support import SearchTestCase, search
from query_understanding import understand


class AccountSearchTest(SearchTestCase):
    entity = "account"

    @classmethod
    def key(cls, source):
        return source["account_ref"]

    def test_identifier_is_exact(self):
        self.run_cases([
            ("full reference, near twin exists", {"ref": "acct_7Q2M9K"}, {"acct_7Q2M9K": "ref_exact"}, ["acct_7Q2M9X"], True),
            ("one character away", {"ref": "acct_7Q2M9Z"}, {}, [], True),
            ("other case", {"ref": "acct_7q2m9k"}, {}, [], True),
            ("partial", {"ref": "acct_7Q2M"}, {}, [], True),
        ])

    def test_company_names(self):
        self.run_cases([
            ("reordered words", {"query": "traders northwind"}, {"acct_7Q2M9K": "name_words"}, [], True),
            ("legal suffix ignored", {"query": "GMBH KESTREL"}, {"acct_7Q2M9X": "name_words"}, [], True),
            ("legal suffix alone", {"query": "ltd"}, {}, [], True),
            ("possessive", {"query": "dante"}, {"acct_DRU001": "name_words"}, [], True),
            ("possessive kept", {"query": "DANTE'S"}, {"acct_DRU001": "name_exact"}, [], True),
            ("possessive joined", {"query": "dantes"}, {}, ["acct_DRU001"], True),
            ("display name", {"query": "harbour lights"}, {"acct_HBL001": "name_exact"}, [], True),
            ("ampersand ignored", {"query": "okafor sons"}, {"acct_OKF001": "name_words"}, [], True),
        ])

    def test_aliases(self):
        self.run_cases([
            ("maintained alias", {"query": "NWT"}, {"acct_7Q2M9K": "alias"}, [], True),
            ("other alias", {"query": "mps"}, {"acct_K3S7R1": "alias"}, [], True),
            ("no typo on aliases", {"query": "NWX", "fuzzy": True}, {}, [], True),
        ])

    def test_prefix(self):
        self.run_cases([
            ("prefix", {"query": "merid"}, {"acct_K3S7R1": "name_prefix"}, [], True),
            ("every word is a prefix", {"query": "merid pac"}, {"acct_K3S7R1": "name_prefix"}, [], True),
            ("two characters", {"query": "me"}, {}, ["acct_K3S7R1"], True),
        ])

    def test_typos(self):
        self.run_cases([
            ("fuzzy off", {"query": "Nortwind"}, {}, ["acct_7Q2M9K"], True),
            ("deletion", {"query": "Nortwind", "fuzzy": True}, {"acct_7Q2M9K": "name_fuzzy"}, [], True),
            ("transposition", {"query": "Northwnid", "fuzzy": True}, {"acct_7Q2M9K": "name_fuzzy"}, [], True),
            ("substitution", {"query": "Kestral", "fuzzy": True}, {"acct_7Q2M9X": "name_fuzzy"}, [], True),
            ("transposition in a longer name", {"query": "Meridain Pacific", "fuzzy": True}, {"acct_K3S7R1": "name_fuzzy"}, [], True),
            ("too far", {"query": "Northwxxx", "fuzzy": True}, {}, ["acct_7Q2M9K"], True),
        ])
        hits = search(self.entity, {"query": "Kestrel", "fuzzy": True}, self.key)
        self.assertEqual(hits[0][0], "acct_7Q2M9X")
        self.assertIn("name_exact", hits[0][1])

    def test_notes_word_forms(self):
        self.run_cases([
            ("plural + past tense", {"query": "refund delay"}, {"acct_7Q2M9K": "notes_words"}, [], True),
            ("-s + -ing", {"query": "audit run"}, {"acct_7Q2M9K": "notes_words"}, [], True),
            ("another word", {"query": "auditor"}, {"acct_SLT001": "notes_words"}, ["acct_7Q2M9K"], True),
            ("three words", {"query": "order pause warehouse"}, {"acct_K3S7R1": "notes_words"}, [], True),
            ("not a word form", {"query": "orderly"}, {}, [], True),
            ("past participle", {"query": "invoice dispute"}, {"acct_7Q2M9X": "notes_words"}, [], True),
            # Porter reduces organic and organization to organ: the keyword_marker keeps them apart
            ("over-stemming guard", {"query": "organ"}, {"acct_W1L0W5": "notes_words"},
             {"acct_GRN001": ["notes_words"], "acct_OKF001": ["notes_words"]}, False),
            ("protected word", {"query": "organic"}, {"acct_GRN001": "notes_words"}, {"acct_W1L0W5": ["notes_words"]}, False),
            ("stop words only", {"query": "the"}, {}, [], True),
        ])

    def test_phrase_and_broader(self):
        self.run_cases([
            ("strict phrase", {"phrase": "refunds delayed"}, {"acct_7Q2M9K": "notes_phrase"}, [], True),
            ("phrase is not stemmed", {"phrase": "refund delay"}, {}, [], True),
            ("all words required", {"query": "refund warehouse"}, {}, [], True),
            ("broader results, labeled", {"query": "refund warehouse", "broader": True},
             {"acct_7Q2M9K": "notes_subset", "acct_K3S7R1": "notes_subset"}, [], True),
        ])

    def test_fixed_list_filters(self):
        self.run_cases([
            ("status", {"status": "SUSPENDED"}, {"acct_OKF001": None}, [], True),
            ("status resolved from wording", {"status": understand("account", "status", "frozen")["value"]}, {"acct_OKF001": None}, [], True),
            ("base currency", {"currency": understand("account", "base_currency", "nok")["value"]}, {"acct_FJD001": None}, [], True),
            ("no fuzziness in ES", {"currency": "NKO"}, {}, [], True),
        ])

    def test_amounts_need_a_currency(self):
        eur = understand("account", "amount", "2,500.00 EUR")
        self.run_cases([
            ("amount + currency", {"amount_currency": eur["currency"], "amount_gte": eur["amount"], "amount_lte": eur["amount"]},
             {"acct_7Q2M9X": None}, ["acct_K3S7R1", "acct_W1L0W5"], True),
            ("credit currency, not base", {"amount_currency": "EUR", "amount_gte": 10000, "amount_lte": 10000}, {"acct_SLD001": None}, [], True),
            ("zero-decimal currency", {"amount_currency": "JPY", "amount_gte": 5000000, "amount_lte": 5000000}, {"acct_SLT001": None}, [], True),
            # without amount_currency the template applies no amount filter at all
            ("amount without currency", {"amount_gte": 2500, "amount_lte": 2500, "size": 100},
             {"acct_7Q2M9K": None, "acct_OAK001": None}, [], False),
        ])

    def test_opened_range(self):
        self.run_cases([
            ("year", {"opened_gte": "2025-01-01", "opened_lt": "2026-01-01", "size": 100},
             {"acct_GRN001": None, "acct_OKF001": None, "acct_DRU001": None, "acct_HBL001": None, "acct_SLT001": None}, [], True),
        ])


if __name__ == "__main__":
    unittest.main()
