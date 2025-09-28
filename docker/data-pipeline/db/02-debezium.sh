#!/bin/bash
set -e
export PGPASSWORD=$POSTGRES_PASSWORD;

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  -- CREATE USER ${APP_DB_USER} WITH PASSWORD '${APP_DB_PASS}';
  CREATE ROLE ${APP_DB_USER}_user WITH LOGIN PASSWORD '${APP_DB_PASS}' REPLICATION;

  -- Give permission to all table 
  GRANT SELECT          ON ALL TABLES                   IN SCHEMA ${APP_DB_SCHEMA} TO ${APP_DB_USER};
  ALTER DEFAULT PRIVILEGES                              IN SCHEMA ${APP_DB_SCHEMA} GRANT SELECT ON TABLES TO ${APP_DB_USER};

  -- Create publication
  CREATE PUBLICATION dbz_publication FOR ALL TABLES;

  \connect ${APP_DB_NAME} ${APP_DB_USER};

  BEGIN;

  COMMIT;
EOSQL
