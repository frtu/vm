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
#   install-es-sink [version] Download the Confluent Elasticsearch sink plugin into
#                             debezium-connector/plugins (default 15.0.2), then
#                             recreate kafka-connect: stack.sh up kafka-connect
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

ES_SINK_DIR="$STACK_DIR/debezium-connector/plugins/kafka-connect-elasticsearch"

cmd_install_es_sink() {
  require unzip
  local version="${1:-15.0.2}" tmp
  local name="confluentinc-kafka-connect-elasticsearch-$version"
  tmp="$(mktemp -d)"
  log "downloading $name"
  curl -fsSL -o "$tmp/$name.zip" \
    "https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-elasticsearch/versions/$version/$name.zip"
  unzip -q "$tmp/$name.zip" -d "$tmp"
  mkdir -p "$ES_SINK_DIR"
  rm -rf "${ES_SINK_DIR:?}"/*
  cp -R "$tmp/$name"/. "$ES_SINK_DIR"/
  rm -rf "$tmp"
  log "installed in $ES_SINK_DIR; load it with: scripts/stack.sh up kafka-connect"
}

dispatch "$@"
