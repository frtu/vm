db-pgduckdb
===

Classic PostgreSQL image (```postgres:<version>-bookworm```) extended with the [pg_duckdb](https://github.com/duckdb/pg_duckdb) extension (DuckDB analytical engine embedded in Postgres), compiled from source by ```Dockerfile```.

Setup follows [db-postgres](../db-postgres) (same env variables, init scripts & pgadmin).

## Usage

Build & start with ```docker compose up -d --build```

> First build compiles DuckDB from source and can take 20+ minutes. Next builds reuse the ccache mount.

You will be able to have :

* postgres + pg_duckdb : port ```5432``` default database ```postgres``` (root / admin), app database ```db``` (user / pass)
* pgadmin : [http://localhost:8008/](http://localhost:8008/) (admin@pgadmin.org / admin)

### Versions

Set in ```.env``` then rebuild with ```docker compose build``` :

* ```POSTGRESQL_VERSION``` : postgres major version (pg_duckdb supports 14 to 18), default ```17```
* ```PG_DUCKDB_VERSION``` : git tag or branch of [pg_duckdb](https://github.com/duckdb/pg_duckdb/tags), default ```main```
* ```DUCKDB_VERSION``` : override the embedded DuckDB version (empty = pg_duckdb default), default ```v1.5.5```. Community extensions are built per DuckDB version, and ```ossie``` is only published for ```v1.5.5``` (pg_duckdb ```main``` ships ```v1.5.4```, ```v1.1.1``` ships ```v1.4.3```).

### Connect

	docker compose exec postgres psql -U root

### Enable the extension

```shared_preload_libraries='pg_duckdb'``` is set in the image. ```db/init/01-init.sh``` creates the extension in ```postgres``` and the app database on first start. To enable it manually in another database :

```
CREATE EXTENSION IF NOT EXISTS pg_duckdb;
```

### Force DuckDB acceleration

Run standard PostgreSQL queries, or force the DuckDB analytical execution engine for heavy queries :

```
SET duckdb.force_execution = true;
```

## DuckDB-Ossie semantic layer

[ossie](https://duckdb.org/community_extensions/extensions/ossie) parses Apache Ossie semantic models (YAML/JSON) and answers semantic queries. Inside pg_duckdb, DuckDB functions are called through ```duckdb.raw_query``` / ```duckdb.query```, and Postgres tables are visible in DuckDB as ```pgduckdb.<schema>.<table>```.

Models go into ```./models``` (mounted read-only at ```/models```). Example with ```models/sales_model.json``` (superuser, to read files) :

```
CREATE TABLE orders(order_id INTEGER, customer_id INTEGER, amount DECIMAL(10,2));
CREATE TABLE customers(customer_id INTEGER, country VARCHAR);
INSERT INTO orders VALUES (1,1,100.00),(2,1,250.00),(3,2,75.00);
INSERT INTO customers VALUES (1,'US'),(2,'DE');

-- Load the model in the session DuckDB instance
SELECT duckdb.raw_query($$ CALL ossie_load('/models/sales_model.json') $$);

-- Discover the vocabulary
SELECT * FROM duckdb.query($$ SELECT name, expression FROM ossie_metrics() $$);
SELECT * FROM duckdb.query($$ SELECT dataset, name FROM ossie_fields() $$);

-- Semantic query : metrics, dimensions, filters
SELECT * FROM duckdb.query($$ SELECT * FROM ossie_query(['revenue'], ['customers.country']) $$);

-- Or only compile to SQL
SELECT * FROM duckdb.query($$ SELECT ossie_compile(['revenue'], ['customers.country'], []) $$);
```

Install manually (e.g. in another database) :

```
SET duckdb.allow_community_extensions = true;
SELECT duckdb.install_extension('ossie', 'community');
SELECT duckdb.install_extension('duckdb_mcp', 'community');
SELECT * FROM duckdb.extensions;
```

> ```duckdb_mcp``` is installed for its MCP **client** functions (```ATTACH ... (TYPE mcp)```, ```mcp_call_tool```). Its stdio MCP **server** mode (```mcp_server_start('stdio')```) needs to own the process stdin/stdout, which a Postgres backend does not have, so serving the semantic layer to an AI client (Claude Desktop) requires a standalone DuckDB CLI process instead.

## Auto init DB

Scripts in ```./db/init``` run on first start (empty ```./db/data```) :

* ```01-init.sh``` : create app user, database, schema & extensions
* ```02-enable-motherduck.sql``` : enable [MotherDuck](https://motherduck.com/) if ```MOTHERDUCK_TOKEN``` is set in ```.env``` (no-op otherwise)
* ```03-install-ossie.sh``` : install ```ossie``` & ```duckdb_mcp``` community extensions in ```postgres``` and the app database

Reset with ```docker compose down && rm -rf db/data```.

## Configuration Tips

* Port conflict : ```db-postgres``` also uses ```5432``` & ```8008```, set ```DB_PORT``` / ```DB_UI_PORT``` in ```.env``` to run both.
