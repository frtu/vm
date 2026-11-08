# AGENTS.md

Guidance for AI coding agents working in `docker/data-pipeline`.

## What this is

A local CDC data pipeline stack run with docker compose:
PostgreSQL (source) → Debezium / Kafka Connect → Kafka → Flink → Elasticsearch (sink),
plus Jupyter, Kibana, Kafka UI and Redpanda Console.

Operate it **only through `scripts/`** (see [scripts/README.md](scripts/README.md)).
The full playbook is the [`data-pipeline` skill](skills/data-pipeline/SKILL.md);
load it if your agent supports skills, otherwise read it as instructions.

## Start

```bash
scripts/stack.sh up                 # all services, detached
scripts/stack.sh up postgres kafka  # or a subset
```

The first start pulls large images (Elasticsearch, Flink, Kafka) and can take minutes.

## Check start up

```bash
scripts/stack.sh status             # every service should be "running"
scripts/health.sh --wait 180        # retry until all components answer, or fail after 180s
```

If a service is not `running` or a `health.sh` line says `FAIL`:

```bash
scripts/stack.sh logs <service> 200
```

Typical causes: a port already used on the host (ports are set in `.env`),
Elasticsearch out of memory (`MEM_LIMIT` in `.env`), Kafka Connect waiting for
Kafka / Postgres to become healthy (wait, then re-check).

## Check

```bash
scripts/health.sh                   # one pass, exit code 0 only if all OK
scripts/stack.sh urls               # UIs and APIs to share with the user
```

Deeper, per component:

| Component | Check |
|---|---|
| PostgreSQL | `scripts/db.sh tables`, `scripts/db.sh slots` (replication slot / publication) |
| Kafka Connect | `scripts/connector.sh list`, `scripts/connector.sh status <name>` (must be `RUNNING`) |
| Kafka | `scripts/kafka.sh topics`, `scripts/kafka.sh consume <topic> 5` |
| Flink | `scripts/flink.sh overview`, `scripts/flink.sh jobs` |
| Elasticsearch | `scripts/es.sh health` (`green`/`yellow`), `scripts/es.sh indices` |

Report results to the user as a short list of component → OK/FAIL, with the
log excerpt that explains each failure.

## Rules

- Never pass `--yes` (`stack.sh reset-db`, `es.sh delete-index`) without the
  user's explicit confirmation.
- Use non-interactive commands: `db.sh query` not `db.sh psql`.
- `db/data/` is the Postgres data directory (git-ignored): never edit or commit it.
  `db/init/` scripts only run on an empty `db/data`.
- When changing `docker-compose.yml`, `.env` or the scripts, keep
  `scripts/README.md`, the skill and this file in sync.
