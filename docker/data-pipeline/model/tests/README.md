# Domain tests

Standard-library `unittest` (no install needed); `pytest` collects the same files if available.
Stack access goes through `scripts/es.sh` and `scripts/db.sh`; tests that need the stack are
skipped when it isn't reachable.

```bash
# from docker/data-pipeline
python3 -m unittest discover -s model/tests            # everything
python3 -m unittest discover -s model/tests -p 'test_q*'   # offline only
cd model/tests && python3 -m unittest -v test_accounts_search
```

| File | Stack | Checks |
|---|---|---|
| `test_catalog.py` | no | catalogs, mappings, migrations and pipelines describe the same model: every field cataloged, ES paths and template parameters exist, every column cataloged, fixed lists consistent and unanalyzed, status codes / legal suffixes / currency exponents identical in catalog and ES files, migration versions |
| `test_query_understanding.py` | no | `catalog/query_understanding.py`: resolved / suggested / ambiguous / invalid values, en amounts with currency, ambiguous dates |
| `test_elasticsearch.py` | yes | live mappings, pipelines and stored search templates equal the files; templates render; analyzer tokens; normalizers; pipeline simulation (status labels, contact routing, credit units) |
| `test_cdc_sync.py` | yes | every Postgres row is a document with the pipeline applied (waits up to `SYNC_TIMEOUT_S`, 60 s) |
| `test_customers_search.py` | yes | `customers-general`: identifiers, hyphens, accents, apostrophes, prefixes, bounded typos, email / phone lookup and fragments, filters, dates with time zone |
| `test_contacts_search.py` | yes | `contacts-lookup`: email / phone lookup, fragments, last 4 digits, shared numbers, filters |
| `test_accounts_search.py` | yes | `accounts-general`: identifiers, legal suffixes, possessives, aliases, prefixes, typos, English word forms, over-stemming guard, phrases, broader results, fixed lists via Query Understanding, amounts with currency, date range |

A search case is `(label, params, found, not_found, exact)` (see `support.SearchTestCase.run_cases`):
`found` maps the expected hits to the named query that must explain them, `not_found` lists hits that
must be absent, or maps a hit to the named queries that must not have matched it (`darcy` may
find D'Arcy through her email, never through a name tier). Search cases run the template *files*
inline, so a change is tested before it is applied.

Environment: `INDEX_SUFFIX` (default `_connect`) to test copies of the indices,
`SYNC_TIMEOUT_S` (default 60).
