#!/usr/bin/env bash
# Check that every component of the stack is reachable.
#
# Usage: scripts/health.sh [--wait <seconds>]
#
#   --wait N   Retry until all checks pass or N seconds elapse (default: single pass)
#
# Prints one line per component (OK / FAIL). Exit code 0 only if all pass.
source "$(dirname "$0")/_lib.sh"
require docker curl

WAIT=0
case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  --wait) WAIT="${2:-60}" ;;
  "") ;;
  *) usage >&2; die "unknown argument: $1" ;;
esac

http_ok() { curl -fsS -o /dev/null --max-time 5 "$1" 2>/dev/null; }
pg_ok()    { dc exec -T postgres pg_isready -q -U "$APP_DB_USER" -d "$APP_DB_NAME" >/dev/null 2>&1; }
kafka_ok() { dc exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; }

check() {
  local name="$1"; shift
  if "$@"; then printf '  %-15s OK\n' "$name"; return 0
  else printf '  %-15s FAIL\n' "$name"; return 1; fi
}

run_checks() {
  local failed=0
  check postgres      pg_ok || failed=1
  check kafka         kafka_ok || failed=1
  check kafka-connect http_ok "$KAFKA_CONNECT_URL/connectors" || failed=1
  check flink         http_ok "$FLINK_URL/overview" || failed=1
  check elasticsearch http_ok "$ES_URL/_cluster/health" || failed=1
  check kibana        http_ok "$KIBANA_URL/api/status" || failed=1
  check kafka-ui      http_ok "$KAFKA_UI_URL" || failed=1
  check redpanda      http_ok "$REDPANDA_URL" || failed=1
  check jupyter       http_ok "$JUPYTER_URL" || failed=1
  return $failed
}

start=$(date +%s)
while true; do
  if run_checks; then log "all components healthy"; exit 0; fi
  now=$(date +%s)
  if [ $((now - start)) -ge "$WAIT" ]; then die "some components are unhealthy"; fi
  log "retrying in 5s..."
  sleep 5
done
