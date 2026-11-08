#!/usr/bin/env bash
# Build, submit and manage Flink jobs on the local cluster.
#
# Usage: scripts/flink.sh <command> [args]
#
# Commands:
#   build [project]           Build the fat jar with Gradle (default project: flink-pipeline)
#   submit [project] [args]   Submit <project>/build/libs/<project>.jar to the jobmanager
#                             (detached). Extra args are passed to the job.
#   jobs                      List jobs (id, name, state)
#   job <job-id>              Show details of one job
#   cancel <job-id>           Cancel a running job
#   overview                  Cluster overview (task managers, slots)
#
# The stack directory is mounted at /workspace inside the jobmanager container.
source "$(dirname "$0")/_lib.sh"
require curl

DEFAULT_PROJECT="flink-pipeline"

cmd_build() {
  local project="${1:-$DEFAULT_PROJECT}"
  [ -x "$STACK_DIR/$project/gradlew" ] || die "no gradlew in $project"
  log "building $project"
  (cd "$STACK_DIR/$project" && ./gradlew --quiet shadowJar)
  ls -lh "$STACK_DIR/$project/build/libs/"
}

cmd_submit() {
  require docker
  local project="${1:-$DEFAULT_PROJECT}"
  shift || true
  local jar="build/libs/$project.jar"
  [ -f "$STACK_DIR/$project/$jar" ] || die "$project/$jar not found, run: flink.sh build $project"
  log "submitting /workspace/$project/$jar"
  dc exec -T jobmanager /opt/flink/bin/flink run -d "/workspace/$project/$jar" "$@"
}

cmd_jobs() {
  if command -v jq >/dev/null 2>&1; then
    curl -fsS "$FLINK_URL/jobs/overview" \
      | jq -r '.jobs[] | [.jid, .state, .name] | @tsv'
  else
    curl -fsS "$FLINK_URL/jobs/overview"
  fi
}

cmd_job() {
  [ -n "${1:-}" ] || die "usage: flink.sh job <job-id>"
  curl -fsS "$FLINK_URL/jobs/$1" | pretty
}

cmd_cancel() {
  [ -n "${1:-}" ] || die "usage: flink.sh cancel <job-id>"
  curl -fsS -X PATCH "$FLINK_URL/jobs/$1?mode=cancel" >/dev/null && log "cancel requested for $1"
}

cmd_overview() { curl -fsS "$FLINK_URL/overview" | pretty; }

dispatch "$@"
