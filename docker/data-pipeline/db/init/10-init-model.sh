#!/usr/bin/env bash
# First start of an empty database (db/data): create the inventory model with the Flyway
# migrations of ../../model/migration, mounted at /model-migration by docker-compose.yml.
#
# Files run in version order (V1, V2, V3, V11, ..., V23): a plain glob would run V11__ before V1__.
# Every migration is idempotent (IF NOT EXISTS, ON CONFLICT DO NOTHING), so a later
# `scripts/migrate.sh migrate` replays them without change and records the Flyway history.
#
#   MODEL_INIT_DRY_RUN=1 MODEL_MIGRATION_DIR=model/migration db/init/10-init-model.sh   # print the order
set -euo pipefail

MIGRATION_DIR="${MODEL_MIGRATION_DIR:-/model-migration}"

ordered() {
  for f in "$MIGRATION_DIR"/V*__*.sql; do
    v="${f##*/V}"
    echo "${v%%__*} $f"
  done | sort -n | cut -d' ' -f2-
}

if [ "${MODEL_INIT_DRY_RUN:-}" = "1" ]; then
  ordered
  exit 0
fi

ordered | while read -r f; do
  echo "init-model: $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done
