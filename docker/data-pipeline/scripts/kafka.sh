#!/usr/bin/env bash
# Inspect Kafka topics and messages (runs the Kafka CLI inside the broker container).
#
# Usage: scripts/kafka.sh <command> [args]
#
# Commands:
#   topics                          List topics
#   describe <topic>                Describe partitions / offsets of a topic
#   consume <topic> [max] [--tail]  Print up to max messages (default 10) from the
#                                   beginning, or only new ones with --tail. Stops
#                                   after 10s without new messages.
#   produce <topic>                 Send lines from stdin as messages
#   create <topic> [partitions]     Create a topic (default 1 partition)
#   groups                          List consumer groups with lag
source "$(dirname "$0")/_lib.sh"
require docker

BOOTSTRAP="localhost:9092"
k() { dc exec -T kafka "$@"; }

cmd_topics() { k kafka-topics --bootstrap-server "$BOOTSTRAP" --list; }

cmd_describe() {
  [ -n "${1:-}" ] || die "usage: kafka.sh describe <topic>"
  k kafka-topics --bootstrap-server "$BOOTSTRAP" --describe --topic "$1"
}

cmd_consume() {
  [ -n "${1:-}" ] || die "usage: kafka.sh consume <topic> [max] [--tail]"
  local topic="$1" max="${2:-10}" from="--from-beginning"
  if [ "${2:-}" = "--tail" ]; then max=10; from=""; fi
  if [ "${3:-}" = "--tail" ]; then from=""; fi
  # shellcheck disable=SC2086
  k kafka-console-consumer --bootstrap-server "$BOOTSTRAP" --topic "$topic" \
    $from --max-messages "$max" --timeout-ms 10000 2>/dev/null || true
}

cmd_produce() {
  [ -n "${1:-}" ] || die "usage: kafka.sh produce <topic>  (messages on stdin)"
  k kafka-console-producer --bootstrap-server "$BOOTSTRAP" --topic "$1"
}

cmd_create() {
  [ -n "${1:-}" ] || die "usage: kafka.sh create <topic> [partitions]"
  k kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
    --topic "$1" --partitions "${2:-1}" --replication-factor 1
}

cmd_groups() {
  k kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" --describe --all-groups
}

dispatch "$@"
