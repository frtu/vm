# AGENTS.md

Guidance for AI coding agents working in `docker/data-pipeline`.

## Read first

[README.md](README.md) is the shared source of truth for humans and agents.
Follow its sections as your instructions:

- **Start**: how to bring the stack up
- **Check start up**: status, `health.sh --wait`, logs, typical causes of failure
- **Check**: health pass and per-component checks

Script reference: [scripts/README.md](scripts/README.md). Full playbook (command
map, CDC and Flink workflows): the [`data-pipeline` skill](skills/data-pipeline/SKILL.md);
load it if your agent supports skills, otherwise read it as instructions.

## Agent-only rules

- Operate the stack **only through `scripts/`**, not raw `docker` / `curl` commands.
- Change the domain schema only through new Flyway files in `flink-cdc-es/domain/migration`
  (`scripts/migrate.sh`), never by editing an applied `V<n>__*.sql`.
- Never pass `--yes` (`stack.sh reset-db`, `es.sh delete-index`) without the
  user's explicit confirmation in the current conversation.
- Use non-interactive commands: `db.sh query` not `db.sh psql`; pipe stdin into
  `kafka.sh produce`.
- Keep output small: `kafka.sh consume <topic> <max>`, `es.sh search <i> <q> <size>`,
  `stack.sh logs <svc> <lines>`.
- If a script fails with "connection refused", run `scripts/stack.sh status` before anything else.
- Report checks to the user as a short list of component → OK/FAIL, with the log
  excerpt that explains each failure.
- `db/data/` is the Postgres data directory (git-ignored): never edit or commit it.
  `db/init/` scripts only run on an empty `db/data`.
- When changing `docker-compose.yml`, `.env` or the scripts, keep `README.md`,
  `scripts/README.md`, the skill and this file in sync.
