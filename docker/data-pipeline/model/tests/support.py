"""Shared helpers of the domain tests: stack access through scripts/ (es.sh, db.sh), entity
definitions, and the search-case assertion used by the test_*_search.py files."""
import json
import os
import subprocess
import sys
import time
import unittest
from pathlib import Path

DOMAIN = Path(__file__).resolve().parents[1]
STACK = DOMAIN.parent
ES_DIR = DOMAIN / "elasticsearch"
CATALOG_DIR = DOMAIN / "catalog"
sys.path.insert(0, str(CATALOG_DIR))

SUFFIX = os.environ.get("INDEX_SUFFIX", "_connect")
SYNC_TIMEOUT_S = int(os.environ.get("SYNC_TIMEOUT_S", "60"))

ENTITIES = {
    "customer": {"table": "inventory.customers", "index": "customers" + SUFFIX, "pipeline": "customers-cdc",
                 "index_template": "customer_index_template.json", "search_template": "customer_search_template.json"},
    "contact": {"table": "inventory.contacts", "index": "contacts" + SUFFIX, "pipeline": "contacts-cdc",
                "index_template": "contact_index_template.json", "search_template": "contact_search_template.json"},
    "account": {"table": "inventory.accounts", "index": "accounts" + SUFFIX, "pipeline": "accounts-cdc",
                "index_template": "account_index_template.json", "search_template": "account_search_template.json"},
}

NAME_TIERS = ["name_exact", "name_words", "name_prefix", "name_fuzzy"]


def load_json(path):
    return json.loads(Path(path).read_text())


def catalog(entity):
    return load_json(CATALOG_DIR / f"{entity}_field_catalog.json")


def mapping(entity):
    return load_json(ES_DIR / ENTITIES[entity]["index_template"])["mappings"]


def run_script(*args):
    out = subprocess.run([str(STACK / "scripts" / args[0]), *args[1:]], capture_output=True, text=True, cwd=STACK)
    if out.returncode != 0:
        raise RuntimeError(f"{' '.join(args[:3])}: {out.stderr.strip()[-500:]}")
    return out.stdout


def es(method, path, body=None):
    args = ["es.sh", "raw", method, path]
    if body is not None:
        args.append(body if isinstance(body, str) else json.dumps(body))
    out = run_script(*args)
    return json.loads(out) if out.strip() else {}


def sql_rows(sql):
    """Rows of a SELECT as dicts (row_to_json through COPY, so values keep their JSON types)."""
    out = run_script("db.sh", "query", f"COPY (SELECT row_to_json(t) FROM ({sql}) t) TO STDOUT")
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def stack_available():
    try:
        es("GET", "/_cluster/health")
        run_script("db.sh", "query", "SELECT 1")
        return True
    except Exception:  # noqa: BLE001 - any failure means the stack is not usable
        return False


def wait_for_sync(entity):
    """Wait until every row of the entity table is a document (CDC is asynchronous)."""
    ids = {str(r["id"]) for r in sql_rows(f"SELECT id FROM {ENTITIES[entity]['table']}")}
    deadline = time.time() + SYNC_TIMEOUT_S
    while True:
        es("POST", f"/{ENTITIES[entity]['index']}/_refresh")
        docs = es("POST", f"/{ENTITIES[entity]['index']}/_search", {"size": 1000, "_source": False})
        doc_ids = {h["_id"] for h in docs["hits"]["hits"]}
        if ids <= doc_ids or time.time() > deadline:
            return ids, doc_ids
        time.sleep(2)


def search(entity, params, key):
    """Run the search template file (not the stored copy) inline; hits as (key, matched_queries, _source)."""
    body = {"source": (ES_DIR / ENTITIES[entity]["search_template"]).read_text(), "params": {"size": 50, **params}}
    hits = es("POST", f"/{ENTITIES[entity]['index']}/_search/template", body)["hits"]["hits"]
    return [(key(h["_source"]), set(h.get("matched_queries", [])), h["_source"]) for h in hits]


@unittest.skipUnless(stack_available(), "stack not reachable (scripts/stack.sh status)")
class StackTestCase(unittest.TestCase):
    """Base class of the tests that need Postgres and Elasticsearch."""


class SearchTestCase(StackTestCase):
    entity = None

    @classmethod
    def setUpClass(cls):
        wait_for_sync(cls.entity)

    @classmethod
    def key(cls, source):
        raise NotImplementedError

    def run_cases(self, cases):
        """cases: (label, params, found, not_found, exact)
        found      {key: tier or None}  must be a hit, matched by that named query when a tier is given
        not_found  [keys]               must not be a hit
                   {key: [tiers]}       may be a hit, but never through these named queries
        exact      the hits are exactly the keys of found"""
        for label, params, found, not_found, exact in cases:
            with self.subTest(label, params=params):
                hits = search(self.entity, params, self.key)
                by_key = {}
                for k, tiers, _ in hits:
                    by_key.setdefault(k, set()).update(tiers)
                shown = {k: sorted(t) for k, t in by_key.items()}
                for k, tier in found.items():
                    self.assertIn(k, by_key, f"{label}: {k} not found, hits {shown}")
                    if tier:
                        self.assertIn(tier, by_key[k], f"{label}: {k} matched by {sorted(by_key[k])}")
                if isinstance(not_found, dict):
                    for k, tiers in not_found.items():
                        self.assertFalse(by_key.get(k, set()) & set(tiers), f"{label}: {k} matched by {shown.get(k)}")
                else:
                    for k in not_found:
                        self.assertNotIn(k, by_key, f"{label}: {k} found, hits {shown}")
                if exact:
                    self.assertEqual(set(found), set(by_key), f"{label}: hits {shown}")
