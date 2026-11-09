"""The catalogs, the migrations and the Elasticsearch files describe the same model. No stack needed."""
import re
import unittest

from support import DOMAIN, ENTITIES, ES_DIR, catalog, load_json, mapping

MIGRATIONS = DOMAIN / "migration"


def es_paths(props, prefix=""):
    paths = set()
    for name, spec in props.items():
        paths.add(prefix + name)
        for sub in spec.get("fields", {}):
            paths.add(f"{prefix}{name}.{sub}")
    return paths


def table_columns(table):
    """Columns of `CREATE TABLE ... (` and `ADD COLUMN IF NOT EXISTS` in the V<n>__create_*.sql files."""
    columns = set()
    for f in sorted(MIGRATIONS.glob("V*__create_*.sql")):
        sql = re.sub(r"--[^\n]*", "", f.read_text())
        m = re.search(rf"CREATE TABLE IF NOT EXISTS {re.escape(table)} \((.*?)\n\);", sql, re.S)
        if m:
            columns |= {line.split()[0] for line in m.group(1).split("\n")
                        if line.strip() and not line.strip().startswith(("UNIQUE", "PRIMARY", "CHECK"))}
        for alter in re.findall(rf"ALTER TABLE {re.escape(table)}\s+(ADD COLUMN.*?);", sql, re.S):
            columns |= set(re.findall(r"ADD COLUMN IF NOT EXISTS (\w+)", alter))
    return columns


class CatalogTest(unittest.TestCase):
    def test_catalog_and_mapping_list_the_same_fields(self):
        for entity in ENTITIES:
            with self.subTest(entity=entity):
                fields = {f["field"] for f in catalog(entity)["fields"]}
                self.assertEqual(fields, set(mapping(entity)["properties"]))

    def test_es_paths_exist(self):
        for entity in ENTITIES:
            paths = es_paths(mapping(entity)["properties"])
            for f in catalog(entity)["fields"]:
                for role, value in f["es"].items():
                    with self.subTest(entity=entity, field=f["field"], role=role):
                        self.assertIn(value.split()[0], paths)

    def test_params_exist_in_the_search_template(self):
        for entity, e in ENTITIES.items():
            template = (ES_DIR / e["search_template"]).read_text()
            for f in catalog(entity)["fields"]:
                for part in (f["param"] or "").split(","):
                    name = re.match(r"\s*(\w+)", part)
                    if not name:
                        continue
                    with self.subTest(entity=entity, field=f["field"], param=name.group(1)):
                        self.assertRegex(template, r"\{\{[#^]?" + name.group(1) + r"\}\}")

    def test_every_field_has_a_category_and_a_spec(self):
        for entity in ENTITIES:
            for f in catalog(entity)["fields"]:
                with self.subTest(entity=entity, field=f["field"]):
                    self.assertTrue(f["category"])
                    self.assertTrue(f["spec"])
                    self.assertTrue(set(f["behaviors"]) <= {"blur", "stemming", "fuzzy", "fixed_list"})

    def test_fixed_lists(self):
        for entity in ENTITIES:
            for f in catalog(entity)["fields"]:
                if "fixed_list" not in f["behaviors"] or "values_from" in f:
                    continue
                with self.subTest(entity=entity, field=f["field"]):
                    codes = [v["code"] for v in f["values"]]
                    self.assertEqual(len(codes), len(set(codes)))
                    for choices in f.get("ambiguous", {}).values():
                        self.assertTrue(set(choices) <= set(codes))
                    words = [w for v in f["values"] for w in v["labels"] + v["wording"]]
                    self.assertEqual(len(words), len(set(words)), "a word maps to one value only")
                    self.assertFalse(set(words) & set(f.get("ambiguous", {})), "a word is either curated or ambiguous")

    def test_fixed_lists_are_not_analyzed(self):
        for entity in ENTITIES:
            props = mapping(entity)["properties"]
            for f in catalog(entity)["fields"]:
                if "fixed_list" in f["behaviors"]:
                    with self.subTest(entity=entity, field=f["field"]):
                        self.assertEqual(props[f["field"]]["type"], "keyword")
                        self.assertNotIn("normalizer", props[f["field"]])

    def test_columns_are_cataloged(self):
        for entity, e in ENTITIES.items():
            columns = table_columns(e["table"])
            described = " ".join(f["column"] for f in catalog(entity)["fields"])
            for column in columns:
                with self.subTest(entity=entity, column=column):
                    self.assertIn(column, described)

    def test_customer_status_codes_match_the_pipeline(self):
        source = load_json(ES_DIR / "customer_ingest_pipeline.json")["processors"][-1]["script"]["source"]
        codes = dict(re.findall(r"'(\d)': '(\w+)'", source))
        spec = next(f for f in catalog("customer")["fields"] if f["field"] == "status")
        self.assertEqual(codes, spec["codes"])
        self.assertEqual(set(codes.values()), {v["code"] for v in spec["values"]})

    def test_account_status_codes_match_the_table(self):
        sql = (MIGRATIONS / "V3__create_account.sql").read_text()
        check = re.search(r"status IN \(([^)]*)\)", sql).group(1)
        spec = next(f for f in catalog("account")["fields"] if f["field"] == "status")
        self.assertEqual(set(re.findall(r"'(\w+)'", check)), {v["code"] for v in spec["values"]})

    def test_legal_suffixes_match_the_analyzer(self):
        analysis = load_json(ES_DIR / "common_component_template.json")["template"]["settings"]["analysis"]
        spec = next(f for f in catalog("account")["fields"] if f["field"] == "legal_name")
        self.assertEqual(analysis["filter"]["legal_suffix_stop"]["stopwords"], spec["legal_suffixes"])

    def test_minor_unit_exponents_match_the_pipeline(self):
        source = load_json(ES_DIR / "account_ingest_pipeline.json")["processors"][1]["script"]["source"]
        exponents = {k: int(v) for k, v in re.findall(r"'([A-Z]{3})': (\d)", source)}
        spec = next(f for f in catalog("account")["fields"] if f["field"] == "credit_limit")
        self.assertEqual({**exponents, "default": 2}, spec["minor_unit_exponents"])

    def test_metadata_lists_every_file(self):
        meta = load_json(ES_DIR / "auto_apply_metadata.json")
        files = {e["filename"] for group in meta.values() for e in group}
        self.assertEqual(files, {p.name for p in ES_DIR.glob("*.json")} - {"auto_apply_metadata.json"})

    def test_migration_versions(self):
        versions = sorted(int(p.name[1:].split("__")[0]) for p in MIGRATIONS.glob("V*.sql"))
        self.assertEqual(versions, [1, 2, 3, 11, 12, 13, 21, 22, 23])


if __name__ == "__main__":
    unittest.main()
