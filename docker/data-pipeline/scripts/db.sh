#!/usr/bin/env bash
# Interact with the PostgreSQL source database (runs psql inside the container,
# no local psql needed).
#
# Usage: scripts/db.sh <command> [args]
#
# Commands:
#   psql                 Open an interactive psql shell
#   query "<sql>"        Run SQL and print the result (use "-" to read SQL from stdin)
#   file <path.sql>      Run a SQL file
#   tables [schema]      List tables (default: all non-system schemas)
#   slots                Show replication slots and publications (Debezium CDC state)
#
# Connection: db=$APP_DB_NAME user=$APP_DB_USER (from .env)
source "$(dirname "$0")/_lib.sh"
require docker

psql_exec() {
  dc exec -T -e PGPASSWORD="$APP_DB_PASSWORD" postgres \
    psql -v ON_ERROR_STOP=1 -U "$APP_DB_USER" -d "$APP_DB_NAME" "$@"
}

cmd_psql() {
  dc exec -e PGPASSWORD="$APP_DB_PASSWORD" postgres psql -U "$APP_DB_USER" -d "$APP_DB_NAME"
}

cmd_query() {
  [ $# -ge 1 ] || die 'usage: db.sh query "<sql>"  (or "-" for stdin)'
  if [ "$1" = "-" ]; then psql_exec; else psql_exec -c "$1"; fi
}

cmd_file() {
  [ -f "${1:-}" ] || die "usage: db.sh file <path.sql>"
  psql_exec < "$1"
}

cmd_tables() {
  if [ -n "${1:-}" ]; then
    psql_exec -c "\dt $1.*"
  else
    psql_exec -c "SELECT table_schema, table_name FROM information_schema.tables
                  WHERE table_schema NOT IN ('pg_catalog','information_schema')
                  ORDER BY 1,2;"
  fi
}

cmd_slots() {
  psql_exec -c "SELECT slot_name, plugin, active, restart_lsn FROM pg_replication_slots;"
  psql_exec -c "SELECT pubname, puballtables FROM pg_publication;"
  psql_exec -c "SHOW wal_level;"
}

dispatch "$@"
