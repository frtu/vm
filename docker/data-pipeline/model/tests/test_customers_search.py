"""customers-general on customers_connect: one case per behavior of the customer catalog.
Data: migration/V11 (basic) and V21 (variants)."""
import unittest

from support import NAME_TIERS, SearchTestCase


class CustomerSearchTest(SearchTestCase):
    entity = "customer"

    @classmethod
    def key(cls, source):
        return source["customer_ref"]

    def test_identifier_is_exact(self):
        self.run_cases([
            ("full reference", {"ref": "cus_tko2304"}, {"cus_tko2304": "ref_exact"}, [], True),
            ("one character away", {"ref": "cus_tko2305"}, {}, [], True),
            ("other case", {"ref": "CUS_TKO2304"}, {}, [], True),
            ("partial", {"ref": "cus_tko"}, {}, [], True),
        ])

    def test_hyphenated_names(self):
        self.run_cases([
            ("given name part + surname", {"query": "claire dubois"}, {"cus_mcd2403": "name_words"}, [], True),
            ("reordered, upper case", {"query": "DUBOIS MARIE"}, {"cus_mcd2403": "name_words"}, [], True),
            ("whole hyphenated token", {"query": "MARIE-CLAIRE"}, {"cus_mcd2403": "name_words"}, [], False),
            ("joined parts", {"query": "marieclaire"}, {}, ["cus_mcd2403"], True),
            ("surname part", {"query": "hansen lars"}, {"cus_lbh2406": "name_words"}, [], True),
            ("joined surname", {"query": "berghansen"}, {}, ["cus_lbh2406"], True),
        ])

    def test_accents_and_apostrophes(self):
        self.run_cases([
            ("accents folded", {"query": "zoe muller"}, {"cus_zmu2501": "name_exact"}, [], True),
            ("accented query", {"query": "ZOË"}, {"cus_zmu2501": "name_words"}, [], False),
            ("joined", {"query": "zoemuller"}, {}, ["cus_zmu2501"], True),
            # ü is folded to u, not transliterated: mueller only matches the email zoe.mueller@
            ("transliteration", {"query": "mueller"}, {"cus_zmu2501": "email_fragment"}, {"cus_zmu2501": NAME_TIERS}, True),
            ("given name without accent", {"query": "siobhan"}, {"cus_sda2411": "name_words"}, [], False),
            ("apostrophe part", {"query": "arcy"}, {"cus_sda2411": "name_words"}, [], True),
            ("apostrophe kept", {"query": "D'ARCY"}, {"cus_sda2411": "name_words"}, [], True),
            ("apostrophe dropped", {"query": "darcy"}, {"cus_sda2411": "email_fragment"}, {"cus_sda2411": NAME_TIERS}, True),
            ("ø folded", {"query": "soren"}, {"cus_sli2408": "name_words"}, [], False),
        ])

    def test_prefix_from_three_characters(self):
        self.run_cases([
            ("prefix", {"query": "alex"}, {"cus_ape2309": "name_prefix"}, [], True),
            ("every word is a prefix", {"query": "alex petr"}, {"cus_ape2309": "name_prefix"}, [], True),
            ("two characters", {"query": "al"}, {}, ["cus_ape2309"], False),
            ("no nickname", {"query": "Sasha"}, {}, ["cus_ape2309"], True),
        ])

    def test_typos_are_opt_in_and_bounded(self):
        self.run_cases([
            ("fuzzy off", {"query": "Kowalsky"}, {}, ["cus_tko2304"], True),
            ("substitution", {"query": "Kowalsky", "fuzzy": True}, {"cus_tko2304": "name_fuzzy"}, [], True),
            ("insertion", {"query": "Kowalskii", "fuzzy": True}, {"cus_tko2304": "name_fuzzy"}, [], True),
            ("two edits, AUTO:3,64", {"query": "Kovalsky", "fuzzy": True}, {}, ["cus_tko2304"], True),
            ("two edits, ES AUTO", {"query": "Kovalsky", "fuzzy": True, "fuzziness": "AUTO"}, {"cus_tko2304": "name_fuzzy"}, [], True),
            ("deletion", {"query": "Okafr", "fuzzy": True}, {"cus_cok2505": "name_fuzzy"}, [], True),
            ("transposition", {"query": "Okaofr", "fuzzy": True}, {"cus_cok2505": "name_fuzzy"}, [], True),
            ("too far", {"query": "Okxxxx", "fuzzy": True}, {}, ["cus_cok2505"], True),
            ("short word has no edit", {"query": "lu", "fuzzy": True}, {}, ["cus_wli2507"], True),
            ("short word exact", {"query": "li"}, {"cus_wli2507": "name_words"}, [], True),
        ])

    def test_exact_ranks_before_typo(self):
        hits = __import__("support").search(self.entity, {"query": "Tomasz Kowalski", "fuzzy": True}, self.key)
        self.assertEqual(hits[0][0], "cus_tko2304")
        self.assertIn("name_exact", hits[0][1])

    def test_email_lookup_and_fragments(self):
        self.run_cases([
            ("lookup is lowercased", {"email": "OLA.NORDMANN@example.no"}, {"cus_ono2212": "email_exact"}, [], True),
            ("lookup keeps the +tag", {"email": "kai_lee@mailbox.example"}, {}, [], True),
            ("lookup with +tag", {"email": "kai_lee+invoices.2025@mailbox.example"}, {"cus_kle2502": "email_exact"}, [], True),
            ("dotted fragment", {"query": "ola.nordmann"}, {"cus_ono2212": "email_fragment"}, [], True),
            ("words", {"query": "OLA NORDMANN"}, {"cus_ono2212": "name_exact"}, [], True),
            ("joined", {"query": "olanordmann"}, {}, ["cus_ono2212"], True),
            ("+tag fragments", {"query": "invoices 2025"}, {"cus_kle2502": "email_fragment"}, [], True),
            ("domain fragment", {"query": "mailbox"}, {"cus_kle2502": "email_fragment"}, [], True),
            ("joined local part", {"query": "kailee"}, {}, ["cus_kle2502"], True),
        ])

    def test_phone_lookup(self):
        self.run_cases([
            ("formatting ignored", {"phone": "+61 (2) 9374-4000"}, {"cus_kle2502": "phone_exact"}, [], True),
            ("trunk prefix is not a country code", {"phone": "02 9374 4000"}, {}, [], True),
            ("non-breaking hyphen of the original seed", {"phone": "800 555 2100"}, {"cus_bth2302": "phone_exact"}, [], True),
            ("last 4 digits", {"phone_last4": "4000"}, {"cus_kle2502": "phone_last4"}, [], True),
        ])

    def test_fixed_list_filters(self):
        self.run_cases([
            ("status label", {"status": "SUSPENDED"}, {"cus_tko2304": None}, [], True),
            ("status is never fuzzy", {"status": "suspnded"}, {}, [], True),
            ("country", {"country": "NO"}, {"cus_lbh2406": None, "cus_ono2212": None}, [], True),
            ("city", {"city": "Bergen"}, {"cus_ono2212": None}, [], True),
            ("query + filter", {"query": "Davies", "city": "Los Angeles"}, {"cus_sda2302": "name_words"}, [], True),
        ])

    def test_dates_and_time_zone(self):
        self.run_cases([
            ("day in UTC", {"registered_at_gte": "2025-05-07", "registered_at_lt": "2025-05-08"}, {"cus_cok2505": None}, [], True),
            ("other reading of 05/07", {"registered_at_gte": "2025-07-05", "registered_at_lt": "2025-07-06"}, {"cus_wli2507": None}, [], True),
            ("same instant, next day in Tokyo", {"registered_at_gte": "2025-05-08", "registered_at_lt": "2025-05-09", "time_zone": "Asia/Tokyo"},
             {"cus_cok2505": None}, [], True),
        ])


if __name__ == "__main__":
    unittest.main()
