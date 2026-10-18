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

## Auto init DB

Scripts in ```./db/init``` run on first start (empty ```./db/data```) :

* ```01-init.sh``` : create app user, database, schema & extensions
* ```02-enable-motherduck.sql``` : enable [MotherDuck](https://motherduck.com/) if ```MOTHERDUCK_TOKEN``` is set in ```.env``` (no-op otherwise)

Reset with ```docker compose down && rm -rf db/data```.

## Configuration Tips

* Port conflict : ```db-postgres``` also uses ```5432``` & ```8008```, set ```DB_PORT``` / ```DB_UI_PORT``` in ```.env``` to run both.
