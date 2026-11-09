data-pipeline
===

A local CDC data pipeline stack run with docker compose:
PostgreSQL (source) → Debezium / Kafka Connect → Kafka → Flink → Elasticsearch (sink),
plus Jupyter, Kibana, Kafka UI and Redpanda Console.

Operate it with the scripts in [`scripts/`](scripts/README.md) (stack, health, db, CDC connectors, Kafka, Flink, Elasticsearch).
AI agents: see [AGENTS.md](AGENTS.md) and the skill [skills/data-pipeline](skills/data-pipeline/SKILL.md).

## Start

```bash
scripts/stack.sh up                 # all services, detached (same as: docker compose up -d)
scripts/stack.sh up postgres kafka  # or a subset
scripts/stack.sh jupyter up         # Jupyter only (also: down | restart | status | logs | url | open)
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

Typical causes:

* a port already used on the host (ports are set in `.env`)
* Elasticsearch out of memory (`MEM_LIMIT` in `.env`)
* Kafka Connect waiting for Kafka / Postgres to become healthy (wait, then re-check)

## Check

```bash
scripts/health.sh                   # one pass, exit code 0 only if all OK
scripts/stack.sh urls               # UIs and APIs
```

Deeper, per component:

| Component | Check |
|---|---|
| PostgreSQL | `scripts/db.sh tables`, `scripts/db.sh slots` (replication slot / publication) |
| Kafka Connect | `scripts/connector.sh list`, `scripts/connector.sh status <name>` (must be `RUNNING`) |
| Kafka | `scripts/kafka.sh topics`, `scripts/kafka.sh consume <topic> 5` |
| Flink | `scripts/flink.sh overview`, `scripts/flink.sh jobs` |
| Elasticsearch | `scripts/es.sh health` (`green`/`yellow`), `scripts/es.sh indices` |
| Domain migrations | `scripts/migrate.sh info` (Flyway, `model/migration`) |

CDC to ES without Flink (`inventory.customers` / `contacts` / `accounts` -> indices `<table>_connect`, Debezium + Elasticsearch sink
in Kafka Connect): see [model](model/README.md) and the notebook `CDC to ES.ipynb`.

## Endpoints

Open Notebook at : [http://localhost:8888](http://localhost:8888) (or `scripts/stack.sh jupyter open`)

### Data in motion

* Kafka-UI : [http://localhost:18080](http://localhost:18080)
* [Redpanda](https://docs.redpanda.com/current/home/) : [http://localhost:18081](http://localhost:18081)
* Flink UI : [http://localhost:28081](http://localhost:28081)

### Data at Rest

* PostgreSQL : port ```5432``` default database ```postgres```
* Elasticsearch : port ```9200```
* kibana : [http://localhost:5601/](http://localhost:5601/)

## PostgreSQL Config

Connect to postgres using port ```5432```

### Changing password

Edit docker-compose.yml and change the environment properties :

```
postgres_ROOT_PASSWORD: 'admin'

postgres_USER: 'username'
postgres_PASSWORD: 'pass'
```

### Auto init DB

Put your sql commands into ```./db/init/01-init.sh``` :

* Create tables DDL scripts
* Create data DML scripts
