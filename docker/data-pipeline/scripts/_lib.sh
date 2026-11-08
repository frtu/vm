# shellcheck shell=bash
# Shared helpers for data-pipeline scripts. Source it, do not execute it.
# Compatible with macOS bash 3.2.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
cd "$STACK_DIR"

# Load .env so host-side ports / credentials match docker-compose.yml
if [ -f "$STACK_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$STACK_DIR/.env"
  set +a
fi

# Host-side endpoints (defaults mirror docker-compose.yml)
DB_PORT="${DB_PORT:-5432}"
APP_DB_NAME="${APP_DB_NAME:-db}"
APP_DB_USER="${APP_DB_USER:-admin}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-admin}"
KAFKA_CONNECT_URL="http://localhost:${KAFKA_CONNECT_PORT:-8083}"
FLINK_URL="http://localhost:${JOB_MANAGER_PORT:-28081}"
ES_URL="http://localhost:${ES_PORT:-9200}"
KIBANA_URL="http://localhost:${KIBANA_PORT:-5601}"
KAFKA_UI_URL="http://localhost:${KAFKA_UI_PORT:-18080}"
REDPANDA_URL="http://localhost:${REDPANDA_UI_PORT:-18081}"
JUPYTER_URL="http://localhost:8888"

# Logs go to stderr so stdout stays clean for piping (e.g. into jq)
log()  { printf '\033[0;34m[%s]\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; }
warn() { printf '\033[0;33m[%s] WARN:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; }
die()  { printf '\033[0;31m[%s] ERROR:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

require() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || die "'$bin' is required but not installed"
  done
}

dc() { docker compose "$@"; }

# Pretty-print JSON when jq is available, pass through otherwise
pretty() { if command -v jq >/dev/null 2>&1; then jq .; else cat; fi; }

# Print the leading comment block of the calling script as its help
usage() {
  sed -n '2,/^[^#]/{/^#/!q;s/^# \{0,1\}//;p;}' "$0"
}

# Standard dispatch: <script> <command> [args...]
dispatch() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    -h|--help|help) usage ;;
    *)
      if declare -F "cmd_${cmd//-/_}" >/dev/null; then
        "cmd_${cmd//-/_}" "$@"
      else
        usage >&2
        die "unknown command: $cmd"
      fi
      ;;
  esac
}
