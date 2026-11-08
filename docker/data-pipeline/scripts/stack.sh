#!/usr/bin/env bash
# Manage the data-pipeline docker compose stack.
#
# Usage: scripts/stack.sh <command> [args]
#
# Commands:
#   up [service...]     Start the stack (or given services) in the background
#   down                Stop and remove containers (volumes are kept)
#   status              Show containers and their health
#   logs [service] [n]  Show last n log lines (default 100) of a service, or all
#   restart <service>   Restart one service
#   urls                Print the UI / API endpoints
#   reset-db            DESTRUCTIVE: stop postgres, wipe db/data, restart so db/init re-runs.
#                       Requires --yes.
source "$(dirname "$0")/_lib.sh"
require docker

cmd_up() {
  log "starting ${*:-all services}"
  dc up -d "$@"
  dc ps
}

cmd_down() { dc down; }

cmd_status() { dc ps --format 'table {{.Service}}\t{{.State}}\t{{.Status}}\t{{.Ports}}'; }

cmd_logs() {
  local svc="${1:-}" n="${2:-100}"
  if [ -n "$svc" ]; then dc logs --no-color --tail "$n" "$svc"; else dc logs --no-color --tail "$n"; fi
}

cmd_restart() {
  [ $# -ge 1 ] || die "usage: stack.sh restart <service>"
  dc restart "$@"
}

cmd_urls() {
  cat <<EOF
Jupyter        $JUPYTER_URL
Kafka UI       $KAFKA_UI_URL
Redpanda       $REDPANDA_URL
Kafka Connect  $KAFKA_CONNECT_URL
Flink UI       $FLINK_URL
Elasticsearch  $ES_URL
Kibana         $KIBANA_URL
PostgreSQL     localhost:$DB_PORT  db=$APP_DB_NAME user=$APP_DB_USER
Kafka broker   localhost:9092
EOF
}

cmd_reset_db() {
  [ "${1:-}" = "--yes" ] || die "this wipes $STACK_DIR/db/data. Re-run with: stack.sh reset-db --yes"
  dc stop postgres
  dc rm -f postgres
  log "removing db/data"
  rm -rf "$STACK_DIR/db/data"
  dc up -d postgres
  log "postgres restarted; db/init scripts will run on first boot (see: stack.sh logs postgres)"
}

dispatch "$@"
