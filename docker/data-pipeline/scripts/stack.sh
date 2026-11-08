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
#   jupyter <action>    Manage the Jupyter notebook server only:
#                         up | down | restart | status | logs [n] | url | open
#                       (open launches the browser; url prints it)
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

cmd_jupyter() {
  local action="${1:-status}"
  shift || true
  case "$action" in
    up)      dc up -d jupyter && log "Jupyter: $JUPYTER_URL (notebooks in ./notebooks, data in ./data)" ;;
    down)    dc stop jupyter && dc rm -f jupyter ;;
    restart) dc restart jupyter ;;
    status)  dc ps --format 'table {{.Service}}\t{{.State}}\t{{.Status}}\t{{.Ports}}' jupyter ;;
    logs)    dc logs --no-color --tail "${1:-100}" jupyter ;;
    url)     echo "$JUPYTER_URL" ;;
    open)
      curl -fsS -o /dev/null --max-time 5 "$JUPYTER_URL" || die "Jupyter is not reachable, run: stack.sh jupyter up"
      if command -v open >/dev/null 2>&1; then open "$JUPYTER_URL"
      elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$JUPYTER_URL"
      else echo "$JUPYTER_URL"; fi
      ;;
    *) die "usage: stack.sh jupyter up|down|restart|status|logs [n]|url|open" ;;
  esac
}

dispatch "$@"
