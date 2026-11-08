#!/usr/bin/env bash
# Manage Debezium / Kafka Connect connectors through the REST API.
#
# Usage: scripts/connector.sh <command> [args]
#
# Commands:
#   list                      List connectors with their state
#   register [file.json]      Create or update a connector from a JSON file
#                             (default: debezium-connector/postgres-connector.json)
#   status <name>             Show connector and task status
#   config <name>             Show connector config
#   restart <name>            Restart connector and its tasks
#   delete <name>             Delete a connector
#   plugins                   List installed connector plugins
source "$(dirname "$0")/_lib.sh"
require curl

DEFAULT_FILE="$STACK_DIR/debezium-connector/postgres-connector.json"
api() { curl -fsS -H 'Content-Type: application/json' "$@"; }

cmd_list() { api "$KAFKA_CONNECT_URL/connectors?expand=status" | pretty; }

cmd_register() {
  require jq
  local file="${1:-$DEFAULT_FILE}"
  [ -f "$file" ] || die "file not found: $file"
  local name; name="$(jq -r .name "$file")"
  log "registering '$name' from $file"
  # PUT /config is idempotent: creates the connector or updates its config
  jq .config "$file" | api -X PUT --data @- "$KAFKA_CONNECT_URL/connectors/$name/config" | pretty
}

need_name() { [ -n "${1:-}" ] || die "connector name required (see: connector.sh list)"; }

cmd_status()  { need_name "${1:-}"; api "$KAFKA_CONNECT_URL/connectors/$1/status" | pretty; }
cmd_config()  { need_name "${1:-}"; api "$KAFKA_CONNECT_URL/connectors/$1/config" | pretty; }
cmd_restart() { need_name "${1:-}"; api -X POST "$KAFKA_CONNECT_URL/connectors/$1/restart?includeTasks=true" | pretty; }
cmd_delete()  { need_name "${1:-}"; api -X DELETE "$KAFKA_CONNECT_URL/connectors/$1" && log "deleted $1"; }
cmd_plugins() { api "$KAFKA_CONNECT_URL/connector-plugins" | pretty; }

dispatch "$@"
