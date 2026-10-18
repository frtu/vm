#!/bin/bash
# Install DuckDB community extensions (ossie semantic layer + duckdb_mcp) in each pg_duckdb database
# Extensions are stored in $PGDATA/pg_duckdb/extensions and auto-loaded in every session
set -e
export PGPASSWORD=$POSTGRES_PASSWORD;

for DB in "$POSTGRES_DB" "$APP_DB_NAME"; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DB" <<-EOSQL
    SET duckdb.allow_community_extensions = true;
    SELECT duckdb.install_extension('ossie', 'community');
    SELECT duckdb.install_extension('duckdb_mcp', 'community');
    SELECT * FROM duckdb.extensions;
EOSQL
done
