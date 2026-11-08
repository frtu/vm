---
name: data-pipeline
description: >
  Operate the local CDC data pipeline stack (PostgreSQL -> Debezium/Kafka Connect
  -> Kafka -> Flink -> Elasticsearch, plus Jupyter/Kibana/Kafka UI). Use when the
  user asks to start/stop the stack, check health, query the source database,
  register or inspect Debezium connectors, list or consume Kafka topics, build or
  submit Flink jobs, or search Elasticsearch indices in docker/data-pipeline.
compatibility: Requires a shell, docker (compose v2) and curl; jq recommended.
---

# Data Pipeline

All operations go through the scripts in `scripts/` of the `docker/data-pipeline`
directory. They load `.env`, run CLI tools inside the containers (no local
psql/kafka needed) and print data on stdout, logs on stderr. Run every command
from `docker/data-pipeline`, or call the scripts by absolute path.

Full reference: [scripts/README.md](../../scripts/README.md).
Every script supports `help`, e.g. `scripts/kafka.sh help`.

## Command map

| Intent | Command |
|---|---|
| Start / stop | `scripts/stack.sh up [svc...]` / `scripts/stack.sh down` |
| Is it running? | `scripts/stack.sh status`, then `scripts/health.sh` |
| Wait until ready | `scripts/health.sh --wait 180` |
| Logs | `scripts/stack.sh logs <service> [lines]` |
| Endpoints | `scripts/stack.sh urls` |
| Jupyter | `scripts/stack.sh jupyter up / down / status / logs / url` (`open` launches a browser: only if the user asks) |
| SQL | `scripts/db.sh query "SELECT ..."`, `scripts/db.sh tables`, `scripts/db.sh file x.sql` |
| CDC state in Postgres | `scripts/db.sh slots` |
| Connectors | `scripts/connector.sh list / register [file] / status <n> / restart <n>` |
| Topics | `scripts/kafka.sh topics`, `scripts/kafka.sh consume <topic> [max]` |
| Flink | `scripts/flink.sh build`, `scripts/flink.sh submit`, `scripts/flink.sh jobs` |
| Elasticsearch | `scripts/es.sh indices`, `scripts/es.sh search <index> "<q>"` |

Service names: `postgres`, `kafka`, `kafka-connect`, `kafka-ui`, `redpanda`,
`jobmanager`, `taskmanager`, `elasticsearch`, `kibana`, `jupyter`.

## Workflows

**Bring up and verify**
1. `scripts/stack.sh up`
2. `scripts/health.sh --wait 180`; for any FAIL line, read `scripts/stack.sh logs <service> 200`.

**Verify CDC end to end**
1. `scripts/connector.sh list`; if empty, `scripts/connector.sh register`.
2. `scripts/connector.sh status <name>`: connector and tasks must be `RUNNING`; a
   `FAILED` task has a `trace` field with the cause.
3. `scripts/db.sh slots` to confirm the replication slot is active.
4. Change a row with `scripts/db.sh query "UPDATE ..."`.
5. `scripts/kafka.sh topics`, then `scripts/kafka.sh consume <topic.prefix>.<schema>.<table> 5`.

**Deploy a Flink job**
1. `scripts/flink.sh build [project]` (default `flink-cdc-es`, the CDC job).
2. `scripts/flink.sh submit [project]`, then `scripts/flink.sh jobs` to see it `RUNNING`.

## Rules

- Destructive commands need an explicit `--yes`: `stack.sh reset-db --yes`
  (wipes `db/data`) and `es.sh delete-index <i> --yes`. Never add `--yes`
  without the user's confirmation in the current conversation.
- `kafka.sh consume` without a max is capped at 10 messages; keep output small.
- Do not use `db.sh psql` or `kafka.sh produce` without piped input: they are
  interactive. Use `db.sh query` or `echo msg | scripts/kafka.sh produce <topic>`.
- If a script fails with "connection refused", the stack is not up: run
  `scripts/stack.sh status` before anything else.
