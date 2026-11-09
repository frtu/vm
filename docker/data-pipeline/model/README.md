# Domain - inventory

`inventory.customers` (from `../../db/init/10-create_inventory.sql`) indexed in Elasticsearch by CDC
without Flink, with the same documents as the Flink job (index `customers`):

```
migration/ (Flyway)  -> Postgres inventory.customers
  -> Debezium source customers-postgres-source  (../../debezium-connector/customers-postgres-source.json)
  -> Kafka topic     inventory_db.inventory.customers  (unwrapped row + __op / __source_ts_ms / __ts_ms, key = id)
  -> ES sink         customers-es-sink           (../../debezium-connector/customers-es-sink.json)
  -> ingest pipeline customers-cdc               (row -> customer document)
  -> Elasticsearch   index customers_connect     (elasticsearch/)
```

* `migration/`: Flyway, history in `flyway_inventory.flyway_schema_history` (not `public`, which holds
  another app's history, and not `inventory`, captured whole by `postgres-connector`).
  * `V1__create_inventory.sql`: `customers` and `phone_numbers` as in `db/init`, created only if
    missing (no `DROP`); ids start at 1001 / 10001 on a new table; `REPLICA IDENTITY FULL`
  * `V2__insert_inventory.sql`: seed data of `db/init`, a row inserted only if missing
    (customer by email, phone number by customer + value)
* `elasticsearch/` (layout of `search-templates/cases/tech-platform/test`), names in `auto_apply_metadata.json`:
  * `customer_ingest_pipeline.json` (`customers-cdc`): same mapping as `CustomerDocuments.toDocument`
    of the Flink job; `default_pipeline` of the index
  * `customer_index_template.json` (`inventory-customers`, pattern `customers_connect*`): the mapping
    of the Flink index `customers`, explicit (`dynamic: false`), 0 replica (single node stack)
  * `customer_search_template.json` (`customers-general`): `query` on names / email, `city` filter,
    aggregations per city and status

| Postgres column | Postgres type | ES field | ES type |
|---|---|---|---|
| `id` (PK) | `integer` | `id` (= `_id`) | `long` |
| `fname` | `varchar(255)` | `first_name` | `text` + `.keyword` |
| `lname` | `varchar(255)` | `last_name` | `text` + `.keyword` |
| `fname` + `lname` | | `full_name` | `text` + `.keyword` |
| `email`, `street`, `zip`, `city`, `phone` | `varchar(255)` | same name | `text` + `.keyword` |
| `status` | `integer` | `status` | `long` |
| `registered` | `timestamp` (Debezium: µs since epoch) | `registered` (ISO-8601) | `date` |
| Debezium `op` / `source.ts_ms` / `ts_ms` | | `cdc_op` / `cdc_source_ts` / `cdc_processed_ts` | `text` / `date` / `date` |

`phone_numbers` is created and seeded, but not indexed (same as the Flink job).
Change a column in `migration/` (new `V<n>__*.sql`), the pipeline and the index template together.

## Run

From `docker/data-pipeline`, with the stack up:

```bash
scripts/connector.sh install-es-sink   # once: Confluent ES sink plugin into debezium-connector/plugins
scripts/stack.sh up kafka-connect      # reload Kafka Connect with the plugin
scripts/migrate.sh migrate 1           # V1: create the tables if missing
# notebooks/CDC to ES.ipynb: checks PG / ES, creates pipeline + index, registers both connectors
scripts/migrate.sh migrate             # V2: insert the seed data if missing
# notebooks/CDC to ES.ipynb, "Check ES received the data"
```

On a database initialized by `db/init`, V1 / V2 change nothing: the existing customers reach
`customers_connect` with the connector snapshot (`cdc_op` = `r`), new rows as `c`.

Without the notebook: create the pipeline and the index from `elasticsearch/` first (or the sink
creates the index with a dynamic mapping), then `scripts/connector.sh register
debezium-connector/customers-postgres-source.json` (and `customers-es-sink.json`).

Last checked: 2026-11-09, Kafka Connect `debezium/connect:2.5` + `kafka-connect-elasticsearch` 15.0.2,
ES 8.15.3, Flyway 13.11.1: snapshot, insert and delete propagated; documents equal to the Flink
index `customers`.
