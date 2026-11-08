#!/usr/bin/env bash
# Run the Flyway migrations of the domain (flink-cdc-es/domain/migration) against the
# source database, with the one-shot `flyway` service of docker-compose.yml.
#
# Usage: scripts/migrate.sh <command> [args]
#
# Commands:
#   info                 Show applied and pending migrations
#   migrate [version]    Apply pending migrations, only up to [version] when given
#                        (e.g. `migrate 1` creates the table, `migrate` then inserts the data)
#   validate             Check applied migrations match the files
#
# History table: flyway_inventory.flyway_schema_history (not public, not inventory).
source "$(dirname "$0")/_lib.sh"
require docker

flyway() { dc run --rm --no-deps flyway "$@"; }

cmd_info()     { flyway info; }
cmd_validate() { flyway validate; }

cmd_migrate() {
  if [ -n "${1:-}" ]; then
    log "migrating up to version $1"
    flyway migrate "-target=$1"
  else
    log "migrating to the latest version"
    flyway migrate
  fi
}

dispatch "$@"
