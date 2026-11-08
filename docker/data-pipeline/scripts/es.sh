#!/usr/bin/env bash
# Query Elasticsearch (the sink side of the pipeline).
#
# Usage: scripts/es.sh <command> [args]
#
# Commands:
#   health                       Cluster health
#   indices                      List indices with doc count and size
#   count <index>                Number of documents in an index
#   search <index> [q] [size]    Search with a Lucene query string (default: *, size 10)
#   mapping <index>              Show the index mapping
#   delete-index <index> --yes   DESTRUCTIVE: delete an index
#   raw <METHOD> <path> [json]   Any API call, e.g.: es.sh raw GET /_cat/nodes?v
source "$(dirname "$0")/_lib.sh"
require curl

AUTH=()
if [ -n "${ELASTIC_USER:-}" ]; then AUTH=(-u "$ELASTIC_USER:${ELASTIC_PASSWORD:-}"); fi
es() { curl -fsS ${AUTH[@]+"${AUTH[@]}"} -H 'Content-Type: application/json' "$@"; }

need_index() { [ -n "${1:-}" ] || die "index name required (see: es.sh indices)"; }

cmd_health()  { es "$ES_URL/_cluster/health" | pretty; }
cmd_indices() { es "$ES_URL/_cat/indices?v&s=index"; }
cmd_count()   { need_index "${1:-}"; es "$ES_URL/$1/_count" | pretty; }
cmd_mapping() { need_index "${1:-}"; es "$ES_URL/$1/_mapping" | pretty; }

cmd_search() {
  need_index "${1:-}"
  local q="${2:-*}" size="${3:-10}"
  es -G "$ES_URL/$1/_search" --data-urlencode "q=$q" --data-urlencode "size=$size" | pretty
}

cmd_delete_index() {
  need_index "${1:-}"
  [ "${2:-}" = "--yes" ] || die "this deletes index '$1'. Re-run with: es.sh delete-index $1 --yes"
  es -X DELETE "$ES_URL/$1" | pretty
}

cmd_raw() {
  [ $# -ge 2 ] || die "usage: es.sh raw <METHOD> <path> [json-body]"
  local method="$1" path="$2"
  if [ -n "${3:-}" ]; then es -X "$method" "$ES_URL$path" -d "$3" | pretty
  else es -X "$method" "$ES_URL$path" | pretty; fi
}

dispatch "$@"
