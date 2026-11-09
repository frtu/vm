# Project - flink-cdc-es

## About

Flink job (Kotlin) for the CDC pipeline of `docker/data-pipeline`:

```
Postgres inventory.customers
  -> Debezium (Kafka Connect, JSON, schemas disabled)
  -> Kafka topic ecommerce_db.inventory.customers
  -> Flink job customer-cdc-to-elasticsearch   (this project: flink-cdc-es)
  -> Elasticsearch index customers
```

* **Model** (`com.github.frtu.vm.sample.cdc.model`): `Customer` (table row) wrapped in
  `CustomerChangeEvent` (Debezium envelope `before` / `after` / `source` / `op` / `ts_ms`).
* **Source**: `KafkaSource` + `CustomerChangeEventDeserializer` (Jackson). It skips Kafka
  tombstones and unparsable messages.
* **Sink**: `Elasticsearch8AsyncSink`. One document per customer (`_id` = customer id):
  `index` for `c` / `u` / `r` (snapshot), `delete` for `d`. Checkpoints every 10 s
  (at-least-once).
* **Main class**: `com.github.frtu.vm.sample.cdc.CustomerCdcToElasticsearchJob`

Elasticsearch document (index `customers`):

```json
{
  "id": 1001, "first_name": "Brandon", "last_name": "Thomas", "full_name": "Brandon Thomas",
  "email": "brandon.thomas@example.com", "street": "29 Oakwood Drive", "zip": "90210",
  "city": "Los Angeles", "phone": "(800) 555‑2100", "status": 1,
  "registered_at": "2023-02-17T21:36:42Z",
  "cdc_op": "r", "cdc_source_ts": "2026-11-08T15:57:12.211Z", "cdc_processed_ts": "2026-11-08T15:57:12.301Z"
}
```

## Status

Last checked: 2026-11-09 (moved from `../flink-pipeline`) on the local stack (Flink 2.1.0, Kafka cp 7.5.0, Debezium 2.5,
Elasticsearch 8.15.3).

| Item                                        | Status |
|---------------------------------------------|--------|
| Build + unit tests (`./gradlew build`) | OK: 5 tests (`CustomerCdcTest`), `build/libs/flink-cdc-es.jar` (~41 MB) |
| `scripts/flink.sh submit`                   | OK: job `customer-cdc-to-elasticsearch` `RUNNING` |
| Snapshot (`op=r`) -> ES                     | OK: 2 existing customers indexed |
| INSERT / UPDATE / DELETE -> ES              | OK: changes visible in ES within a few seconds |

Versions (`gradle/libs.versions.toml`):

| Dependency                       | Version     | In jar |
|----------------------------------|-------------|--------|
| Flink (`flink-streaming-java`, `flink-clients`) | `2.1.0` (must match the cluster image) | no, `compileOnly` |
| `flink-connector-kafka`          | `5.0.0-2.1` | yes |
| `flink-connector-elasticsearch8` | `4.0.0-2.0` | yes |
| Kotlin                           | `2.1.20`    | yes (stdlib) |
| Jackson (`jackson-module-kotlin`) | `2.17.2`   | yes |

Notes:

* The shadow jar leaves out everything the cluster already provides (Flink core, slf4j,
  log4j). Only connectors, the ES / Kafka clients, Jackson and Kotlin are bundled.
* kafka-clients 4.x uses the relocated `at.yawk.lz4:lz4-java`, which clashes with Flink's
  `org.lz4:lz4-java`. `build.gradle.kts` resolves the clash by picking the highest version.

## Test end to end

Run from the stack directory (`docker/data-pipeline`). It needs JDK 17+ (on this host:
`export JAVA_HOME=~/.sdkman/candidates/java/17.0.18-zulu PATH=$JAVA_HOME/bin:$PATH`).

1. Start the stack and wait until every component is OK:

   ```bash
   scripts/stack.sh up
   scripts/health.sh --wait 240
   ```

   Port 5432 must be free on the host. Stop any other Postgres first.

2. Register the Debezium connector and check the topic:

   ```bash
   scripts/connector.sh register                  # debezium-connector/postgres-connector.json
   scripts/connector.sh status postgres-connector # connector + task RUNNING
   scripts/kafka.sh consume ecommerce_db.inventory.customers 1
   ```

3. Build and submit the job:

   ```bash
   scripts/flink.sh build flink-cdc-es
   scripts/flink.sh submit flink-cdc-es
   scripts/flink.sh jobs                          # customer-cdc-to-elasticsearch RUNNING
   ```

4. Check the snapshot reached Elasticsearch, then change rows:

   ```bash
   scripts/es.sh count customers                  # 2
   scripts/db.sh query "INSERT INTO inventory.customers (first_name,last_name,email,city,status,registered_at) VALUES ('Flink','Test','flink.test@example.com','Singapore',1,now())"
   scripts/es.sh search customers 'email:"flink.test@example.com"' 1   # cdc_op: c
   scripts/db.sh query "UPDATE inventory.customers SET city='Paris' WHERE email='flink.test@example.com'"
   scripts/es.sh search customers 'email:"flink.test@example.com"' 1   # city: Paris, cdc_op: u
   scripts/db.sh query "DELETE FROM inventory.customers WHERE email='flink.test@example.com'"
   scripts/es.sh count customers                  # back to 2
   ```

5. Stop the job: `scripts/flink.sh cancel <job-id>`.

## Run locally

`./gradlew run` starts the job in a local mini-cluster (Flink and log4j are added to the `run`
classpath only). Point it at the host ports and at a separate index / group so it doesn't
interfere with the job on the cluster:

```bash
./gradlew run --args='--kafka.bootstrap-servers localhost:9092 --kafka.group-id flink-cdc-es-local \
  --es.host localhost --es.index customers_local --job.name flink-cdc-es-local'
```

## Configuration

Job arguments (all optional). The defaults match the docker-compose network, as seen from
the Flink containers:

| Argument                  | Default                            |
|---------------------------|------------------------------------|
| `--kafka.bootstrap-servers` | `kafka:29092`                    |
| `--kafka.topic`           | `ecommerce_db.inventory.customers` |
| `--kafka.group-id`        | `flink-pipeline-customers`         |
| `--kafka.starting-offsets` | `earliest` (or `latest`)          |
| `--es.host` / `--es.port` / `--es.scheme` | `elasticsearch` / `9200` / `http` |
| `--es.index`              | `customers`                        |
| `--es.username` / `--es.password` | none (ES security is disabled in `.env`) |
| `--es.max-batch-size` / `--es.max-time-in-buffer-ms` | `500` / `1000` |
| `--checkpoint.interval-ms` | `10000`                           |
| `--job.name`              | `customer-cdc-to-elasticsearch`    |

Example: `scripts/flink.sh submit flink-cdc-es --es.index customers_v2`

## Release notes

### 0.0.1-SNAPSHOT - Current version

* CDC job `CustomerCdcToElasticsearchJob` moved from `../flink-pipeline`
* Gradle 8.8 + Kotlin DSL (Kotlin 2.1.20, Flink 2.1.0), replaces the quickstart Groovy build;
  `pom.xml` and `DataStreamJob.java` are the original quickstart, kept as is
