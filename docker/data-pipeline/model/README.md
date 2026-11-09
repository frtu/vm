# Domain - inventory

Three tables of the `inventory` schema, versioned with Flyway, replicated to Elasticsearch by CDC
(Debezium + Elasticsearch sink), one index per entity:

```
migration/ (Flyway)      Postgres inventory.customers / contacts / accounts
  -> Debezium source     customers-postgres-source  (../debezium-connector, table.include.list = the 3 tables)
  -> Kafka topics        inventory_db.inventory.<table>  (unwrapped row + __op / __source_ts_ms / __ts_ms, key = id)
  -> ES sink             customers-es-sink          (topics.regex, RegexRouter -> <table>_connect)
  -> ingest pipelines    <table>-cdc  (each calls inventory-cdc-common first)
  -> Elasticsearch       customers_connect / contacts_connect / accounts_connect
```

```
domain/
  migration/       Vx create one entity each, V1x basic rows, V2x rows for every search variant
  elasticsearch/   component template (analysis), pipelines, index + search templates; names in auto_apply_metadata.json
  catalog/         <entity>_field_catalog.json (search contract per field) + query_understanding.py
  tools/           apply_elasticsearch.py: puts everything of elasticsearch/ on the stack
  tests/           unittest suite (catalog consistency, analyzers, pipelines, CDC sync, search cases), see tests/README.md
```

## Data model

```
customers 1 ──< contacts      a person and each of their email addresses / phone numbers
customers 1 ──< accounts      a person and the business accounts they own
```

| Table     | Column                                             | SQL type                                      | Category     | ES field (type)                                                                    |
| --------- | -------------------------------------------------- | --------------------------------------------- | ------------ | ---------------------------------------------------------------------------------- |
| customers | `id`                                               | `serial` (from 1001)                          | identifier   | `id` (`long`, = `_id`)                                                             |
|           | `customer_ref`                                     | `varchar(32)` unique                          | identifier   | `customer_ref` (`keyword`)                                                         |
|           | `first_name`, `last_name`                          | `varchar(255)`                                | person name  | `first_name`, `last_name`, `full_name` (`text` + `.keyword` + `.text` + `.prefix`) |
|           | `email`                                            | `varchar(255)` unique                         | contact      | `email` (`keyword`, lowercase normalizer) + `.text` (fragments)                    |
|           | `phone`                                            | `varchar(255)`                                | contact      | `phone` (`keyword`) + `.normalized` (digits) + `.last4`                            |
|           | `street`                                           | `varchar(255)`                                | address line | `street` (`text` + `.keyword` + `.text`)                                           |
|           | `zip`                                              | `varchar(255)`                                | identifier   | `zip` (`keyword`)                                                                  |
|           | `city`                                             | `varchar(255)`                                | label        | `city` (`keyword`) + `.text`                                                       |
|           | `country_code`                                     | `varchar(2)`                                  | fixed list   | `country_code` (`keyword`)                                                         |
|           | `status`                                           | `int` 0..3                                    | fixed list   | `status` (`keyword` label) + `status_code` (`integer`)                             |
|           | `registered_at`                                    | `timestamp`                                   | date         | `registered_at` (`date`)                                                           |
| contacts  | `id`                                               | `serial` (from 10001)                         | identifier   | `id`                                                                               |
|           | `customer_id`                                      | FK customers                                  | identifier   | `customer_id` (`long`)                                                             |
|           | `kind`                                             | `EMAIL` / `PHONE`                             | fixed list   | `kind` (`keyword`)                                                                 |
|           | `label`                                            | `WORK` / `HOME` / `MOBILE` / `BILLING`        | fixed list   | `label` (`keyword`)                                                                |
|           | `value`                                            | `varchar(255)`                                | contact      | `value` (display) and, by kind, `email` or `phone` as above                        |
|           | `preferred`, `verified_at`                         | `boolean`, `timestamp`                        | flag, date   | same names                                                                         |
| accounts  | `id`                                               | `serial` (from 50001)                         | identifier   | `id`                                                                               |
|           | `account_ref`                                      | `varchar(32)` unique                          | identifier   | `account_ref` (`keyword`)                                                          |
|           | `owner_customer_id`                                | FK customers                                  | identifier   | `owner_customer_id` (`long`)                                                       |
|           | `legal_name`, `display_name`                       | `varchar(255)`                                | company name | same names (`text` + `.keyword` + `.text` company + `.prefix`)                     |
|           | `aliases`                                          | `text[]`                                      | alias        | `aliases` (`text` + `.keyword`)                                                    |
|           | `country_code`, `base_currency`, `credit_currency` | ISO codes                                     | fixed list   | same names (`keyword`)                                                             |
|           | `credit_limit_minor`                               | `bigint`                                      | amount       | `credit_limit` (`scaled_float`, major units)                                       |
|           | `payment_terms_days`                               | `int`                                         | amount       | same name (`integer`)                                                              |
|           | `status`                                           | `PENDING` / `ACTIVE` / `SUSPENDED` / `CLOSED` | fixed list   | `status` (`keyword`)                                                               |
|           | `notes`                                            | `text`                                        | free text    | `notes` (`text`, English) + `.exact` (standard)                                    |
|           | `opened_at`                                        | `timestamp`                                   | date         | `opened_at` (`date`)                                                               |
| all       | Debezium `op` / `source.ts_ms` / `ts_ms`           |                                               | technical    | `cdc_op` (`keyword`) / `cdc_source_ts` / `cdc_processed_ts` (`date`)               |

The first `customers` columns (`first_name` ... `registered_at`) are the ones the Flink job `flink-cdc-es`
(class `Customer`, unknown properties ignored) reads; its index `customers` doesn't have the
new fields.

## Modeling concerns

**A field is classified by what its value means, not by its SQL type.** A `varchar` can be a
reference that must match exactly (`customer_ref`), a name people remember approximately
(`last_name`) or an address with its own rules (`email`). The category decides the mapping and the
query; the catalog records it per field with a one-line spec that product and QA can check.

**Each behavior is opted in per field, never globally.** The behaviors are independent:

| Behavior   | What it tolerates                                                | Where                                                  |
| ---------- | ---------------------------------------------------------------- | ------------------------------------------------------ |
| fixed list | the user's wording, resolved to a listed value before the search | statuses, currencies, countries, labels                |
| blur       | case, accents, hyphens / apostrophes, word order                 | names, aliases, email fragments, notes                 |
| fuzzy      | 1 typo from 3 characters, only when the request sets `fuzzy`     | names only, never aliases, references, contacts, codes |
| stemming   | English word forms                                               | notes only                                             |
| prefix     | the start of each word, from 3 characters                        | names (`.prefix`)                                      |

**Lookup and discovery are separate tasks.** Someone with a full reference, email or phone
number wants that record or nothing: `term` on a normalized value, no typo, no partial. Someone with
a fragment (`invoices 2025`, the last 4 digits) gets candidates, never a proof of identity, so each
result carries context to tell them apart (contacts carry `customer_id`; a join to the customer's
name, e.g. with an enrich processor, is not done yet).

**A near match on an identifier is never a hit.** `acct_7Q2M9K` and `acct_7Q2M9X` differ by one
character: a typo tolerance there would silently show another company's account.

**Every match explains itself.** Each query clause has a `_name`, so a hit's `matched_queries`
says whether it was found by the exact phrase, all words, a prefix, an alias, an email fragment, a
typo or the broader subset. The UI never presents an alias or a prefix as a spelling correction.

**Rank by how much of the query matched.** Tiers are weighted: exact phrase (x10) > all words
(x5) > alias (x4) > email fragment (x3) > prefix (x2) > notes (x1) > typo (x0.5) > broader subset
(x0.1). Multi-word queries require every word (`operator: and`); a broader subset match is only
returned on request and labeled.

**Fixed lists are resolved, not fuzzed.** Elasticsearch keeps `status` or `base_currency` as a plain
`keyword`. Query Understanding maps `frozen` to `SUSPENDED` from curated wording, asks the user to
confirm `suspnded`, to choose for `krone` (DKK or NOK) and reports `bitcoin` as invalid instead of
picking the nearest code. The resolved value becomes an editable filter.

**An amount is never searched without its currency.** The template applies `amount_gte` /
`amount_lte` only inside `amount_currency`: 2,500.00 EUR and 2,500.00 SGD are different credit
limits. Amounts are stored in minor units (`BIGINT`: Debezium's default `decimal.handling.mode`
sends `NUMERIC` as base64 bytes) and converted with the ISO 4217 exponent of the currency (JPY has
none, KWD has 3), so `scaled_float` uses a factor of 1000. The credit currency may differ from the
trading currency (Lindqvist Design AB trades in SEK, its credit limit is in EUR).

**Dates need a time zone and an unambiguous reading.** Ranges are `[gte, lt)` with an explicit
`time_zone` (UTC by default): 2025-05-07 23:30 UTC is already 8 May in Tokyo. `05/07/2025` is
returned as ambiguous rather than read as May or July.

**Stemming is a language choice with limits.** The English Porter stemmer matches `refund delay`
with "Refunds delayed", but it also reduces `organic` and `organization` to `organ`; a
`keyword_marker` keeps those whole. It does not relate different words (`auditor` is not `audit`)
and only applies to English text. Quoted phrases (`phrase`) are never stemmed.

**Common words carry no weight.** English stop words in notes and legal suffixes in company names
(the declared list in the component template, mirrored in the account catalog) are dropped on
both sides: `GMBH KESTREL` finds Kestrel Labs GmbH, `ltd` alone finds nothing.

**Aliases are data, owned by the domain.** `NWT` finds Northwind Traders Ltd because it is listed
in `aliases`, not because of a guess. There is no nickname matching (`Sasha` is not `Alexandra`).

**Typo tolerance is conservative.** `fuzziness: AUTO:3,64` = no edit under 3 characters, 1 edit
from 3. The ES default `AUTO` allows 2 edits from 6 characters, so `Kovalsky` would find Kowalski;
a request can still pass `fuzziness: AUTO`.

**Analyzers can't change in place.** A new analyzer or field type needs the index rebuilt and the
rows replayed (see below); adding a field to `dynamic: false` mappings doesn't.

## Design

* `elasticsearch/common_component_template.json` (`inventory-text-analysis`): all analyzers and
  normalizers, listed in `composed_of` of the three index templates.
* `elasticsearch/common_ingest_pipeline.json` (`inventory-cdc-common`): CDC fields, called by each
  entity pipeline. Entity pipelines: customer (`full_name`, status code -> label, timestamps),
  contact (`value` copied to `email` or `phone` by `kind`), account (credit currency default,
  minor -> major units).
* `<entity>_index_template.json`: `dynamic: false`, `_meta` per mapping and `meta` per field
  (category and query rule), so the live mapping documents itself.
* `<entity>_search_template.json`: the parameters and tiers are described in a mustache comment
  at the top of each file. `customers-general`, `contacts-lookup`, `accounts-general`.
* `catalog/<entity>_field_catalog.json`: category, behaviors, ES paths, template parameter,
  examples and spec line per field; fixed-list values, labels, curated and ambiguous wording.
* `catalog/query_understanding.py`: resolves fixed lists, amounts and dates from the catalogs.

## Examples

| Entity   | Request                               | Result                        | Why (`matched_queries`)                                                               |
| -------- | ------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------- |
| customer | `query=claire dubois`                 | Marie-Claire Dubois           | `name_words`: hyphen parts are indexed next to the whole token                        |
| customer | `query=marieclaire`                   | nothing                       | parts are never joined                                                                |
| customer | `query=zoe muller`                    | Zoë Müller                    | `name_exact`: accents folded                                                          |
| customer | `query=mueller`                       | Zoë Müller                    | `email_fragment` only (zoe.mueller@): ü is not transliterated                         |
| customer | `query=darcy`                         | Siobhán D'Arcy                | `email_fragment` only; by name, `arcy` or `D'ARCY`                                    |
| customer | `query=alex petr`                     | Alexandra Petrova             | `name_prefix`, every word is a prefix                                                 |
| customer | `query=Kovalsky&fuzzy=true`           | nothing                       | 2 edits; with `fuzziness=AUTO`: Tomasz Kowalski                                       |
| customer | `query=lu&fuzzy=true`                 | not Wei Li                    | 2 characters, no edit                                                                 |
| customer | `registered_at 2025-05-08, Asia/Tokyo`| Chidi Okafor                  | registered_at 2025-05-07 23:30 UTC                                                    |
| contact  | `email=OLA.NORDMANN@example.no`       | Ola's work email              | `email_exact`, lowercased                                                             |
| contact  | `email=kai_lee@mailbox.example`       | nothing                       | the +tag is part of the address                                                       |
| contact  | `phone=02 9374 4000`                  | nothing                       | stored +61 2 9374 4000: no trunk / country guess                                      |
| contact  | `phone=800 555 2100`                  | Brandon and Sarah             | one number shared by two customers                                                    |
| contact  | `phone_last4=0123`                    | 2 contacts, 2 customers       | discovery returns every match                                                         |
| account  | `ref=acct_7Q2M9K`                     | Northwind only                | not its near twin acct_7Q2M9X                                                         |
| account  | `query=GMBH KESTREL`                  | Kestrel Labs GmbH             | `name_words`, suffix dropped                                                          |
| account  | `query=NWT`                           | Northwind Traders Ltd         | `alias`                                                                               |
| account  | `query=Meridain Pacific&fuzzy=true`   | Meridian Pacific Shipping Ltd | `name_fuzzy`, transposition = 1 edit                                                  |
| account  | `query=refund delay`                  | Northwind                     | `notes_words`: "Refunds delayed"                                                      |
| account  | `query=organ`                         | Willow Organ Builders         | `notes_words`; Greenleaf Organic only by `name_prefix` (organ is a prefix of Organic) |
| account  | `phrase=refund delay`                 | nothing                       | phrases are not stemmed                                                               |
| account  | `query=refund warehouse&broader=true` | Northwind, Meridian           | `notes_subset`, labeled as broader                                                    |
| account  | `2,500.00 EUR`                        | Kestrel Labs                  | `amount_currency=EUR`, not the 2,500.00 SGD account                                   |
| account  | `krone`                               | ask: DKK or NOK               | Query Understanding, ambiguous                                                        |

## Data

* `V11` to `V13`: basic rows, one file per entity (2 customers, their emails and phone numbers as
  contacts, one account each).
* `V21` to `V23`: one row per search variant; each file starts with the table of what it exercises.

Inserts are idempotent (`ON CONFLICT DO NOTHING`, rows linked by email). Change the schema with a
new `V<n>__*.sql`, never by editing an applied file, and keep the catalog, the index template and
the pipeline aligned (`tests/test_catalog.py` checks it).

## Run

On the first start of an empty `db/data`, Postgres runs `db/init/10-init-model.sh`, which applies
`migration/` in version order (mounted at `/model-migration`): the tables and rows exist before
any connector, and the source connector's initial snapshot sends them (`cdc_op` = `r`). The
migrations are idempotent, so `scripts/migrate.sh migrate` then only records the Flyway history.

On an existing database, from `docker/data-pipeline` with the stack up:

```bash
scripts/connector.sh install-es-sink        # once: Confluent ES sink plugin, then scripts/stack.sh up kafka-connect
scripts/migrate.sh migrate 3                # V1-V3: create the tables
python3 model/tools/apply_elasticsearch.py
scripts/connector.sh register debezium-connector/customers-postgres-source.json
scripts/connector.sh register debezium-connector/customers-es-sink.json
scripts/migrate.sh migrate                  # V11-V23: insert the rows
scripts/connector.sh restart customers-es-sink   # new topics: see below
python3 -m unittest discover -s model/tests
```

The sink subscribes with `topics.regex`; a topic created after the sink started (Debezium creates
`inventory_db.inventory.<table>` on the first row) is picked up at the next consumer metadata
refresh (`metadata.max.age.ms`, 5 minutes), or right away after `connector.sh restart customers-es-sink`.

### Rebuild an index

Needed after an analyzer or field type change:

```bash
scripts/es.sh delete-index accounts_connect --yes                  # DESTRUCTIVE
python3 model/tools/apply_elasticsearch.py           # recreates it from the template
scripts/db.sh query "UPDATE inventory.accounts SET id = id"        # one CDC event per row
```

Last checked: 2026-11-09, Kafka Connect `debezium/connect:2.5` + `kafka-connect-elasticsearch`
15.0.2, ES 8.15.3, Flyway 13.11.1: 14 customers, 16 contacts, 13 accounts in sync; 60 tests OK.
