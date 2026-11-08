data-pipeline
===

Start with ```docker-compose up``` (or ```scripts/stack.sh up```)

> Operational scripts for humans & AI agents (stack, health, db, CDC connectors, Kafka, Flink, Elasticsearch): see [scripts/README.md](scripts/README.md). AI agents: [AGENTS.md](AGENTS.md) and skill [skills/data-pipeline](skills/data-pipeline/SKILL.md).

Open Notebook at : [http://localhost:8888](http://localhost:8888)

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
