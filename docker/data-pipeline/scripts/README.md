# data-pipeline scripts

Small, composable bash scripts to operate the local stack
(PostgreSQL → Debezium / Kafka Connect → Kafka → Flink → Elasticsearch).

They are written to be used two ways with the same commands:

- **Humans** run them directly from a terminal.
- **AI agents** (any agent with a shell) run them via [`AGENTS.md`](../AGENTS.md)
  and the [`data-pipeline` skill](../skills/data-pipeline/SKILL.md), or directly.

## Requirements

- `docker` with compose v2 (`docker compose`)
- `curl`
- `jq` (recommended: pretty JSON, `connector.sh register` needs it)

No local `psql` or Kafka CLI is needed: those commands run inside the containers.

## Conventions

- Run from `docker/data-pipeline` (`scripts/<name>.sh ...`), or from anywhere by
  path: each script `cd`s to the stack directory itself.
- Every script reads `../.env`, so ports and credentials always match
  `docker-compose.yml`.
- Form: `scripts/<area>.sh <command> [args]`. `scripts/<area>.sh help` lists commands.
- **stdout = data, stderr = logs.** Output can be piped, e.g.
  `scripts/connector.sh list | jq 'keys'`.
- Exit code is non-zero on failure, so scripts can be chained with `&&`.
- Destructive commands refuse to run without `--yes`.

## Scripts

| Script         | Area                     | Commands                                                                                                                         |
| -------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `stack.sh`     | Docker compose           | `up [svc...]`, `down`, `status`, `logs [svc] [n]`, `restart <svc>`, `urls`, `reset-db --yes`, `jupyter up\|down\|restart\|status\|logs\|url\|open`                                     |
| `health.sh`    | All components           | `[--wait <seconds>]`                                                                                                             |
| `db.sh`        | PostgreSQL               | `psql`, `query "<sql>"` (or `-` for stdin), `file <x.sql>`, `tables [schema]`, `slots`                                           |
| `connector.sh` | Kafka Connect / Debezium | `list`, `register [file.json]`, `status <name>`, `config <name>`, `restart <name>`, `delete <name>`, `plugins`, `install-es-sink [version]` |
| `migrate.sh`   | Flyway (domain migrations) | `info`, `migrate [version]`, `validate` (files in `flink-cdc-es/domain/migration`)                                          |
| `kafka.sh`     | Kafka                    | `topics`, `describe <topic>`, `consume <topic> [max] [--tail]`, `produce <topic>`, `create <topic> [partitions]`, `groups`       |
| `flink.sh`     | Flink                    | `build [project]`, `submit [project] [args]`, `jobs`, `job <id>`, `cancel <id>`, `overview`                                      |
| `es.sh`        | Elasticsearch            | `health`, `indices`, `count <i>`, `search <i> [q] [size]`, `mapping <i>`, `delete-index <i> --yes`, `raw <METHOD> <path> [json]` |
| `_lib.sh`      | shared                   | sourced by the others (env loading, logging, dispatch). Not executable.                                                          |

## Human usage

```bash
cd docker/data-pipeline

# Start everything and wait until it is ready
scripts/stack.sh up
scripts/health.sh --wait 180
scripts/stack.sh urls

# Jupyter only
scripts/stack.sh jupyter up
scripts/stack.sh jupyter open         # opens http://localhost:8888 in the browser

# Source database
scripts/db.sh tables
scripts/db.sh query "SELECT * FROM inventory.customers LIMIT 5"
scripts/db.sh psql                       # interactive shell

# CDC
scripts/connector.sh register            # uses debezium-connector/postgres-connector.json
scripts/connector.sh status postgres-connector
scripts/kafka.sh topics
scripts/kafka.sh consume ecommerce_db.inventory.customers 5

# Domain migrations (Flyway) + CDC to ES without Flink
scripts/connector.sh install-es-sink    # once, then: scripts/stack.sh up kafka-connect
scripts/migrate.sh migrate 1             # create inventory tables if missing
# create ES pipeline + index (notebooks/CDC to ES.ipynb), then:
scripts/connector.sh register debezium-connector/customers-postgres-source.json
scripts/connector.sh register debezium-connector/customers-es-sink.json
scripts/migrate.sh migrate               # insert seed data -> ES index customers_connect

# Flink
scripts/flink.sh build                   # flink-pipeline by default
scripts/flink.sh submit
scripts/flink.sh jobs

# Sink
scripts/es.sh indices
scripts/es.sh search my-index 'city:Singapore' 5

# Troubleshooting
scripts/stack.sh logs kafka-connect 200
```

## AI usage

Agents get two entry points, both agent-agnostic plain Markdown:

| File | Purpose |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Picked up automatically by agents that read `AGENTS.md` (Codex, Cursor, Copilot, Gemini CLI, ...): agent-only rules; points to the Start / Check start up / Check sections of [`README.md`](../README.md) |
| [`skills/data-pipeline/SKILL.md`](../skills/data-pipeline/SKILL.md) | Full playbook in the open [Agent Skills](https://agentskills.io) format: command map, workflows (bring up, verify CDC, deploy Flink job), safety rules |

### With skills support

The skill is stored in the neutral `skills/` folder. Expose it to your agent's
skills directory with a symlink (Claude Code's is already committed):

```bash
# Claude Code (project, committed):  .claude/skills/data-pipeline -> ../../skills/data-pipeline
# Any agent, user-wide, e.g.:
ln -s "$PWD/skills/data-pipeline" ~/.claude/skills/data-pipeline
ln -s "$PWD/skills/data-pipeline" ~/.agents/skills/data-pipeline
```

Then ask in plain language, e.g. *"start the stack and tell me what is unhealthy"*
or *"check that CDC works end to end"*.

To skip permission prompts, allow `scripts/*.sh` in your agent's shell
permission settings (the skill does not grant any by itself).

### Without skills support

Agents that read `AGENTS.md` need nothing else. For others, add to the system
prompt or instructions:

> To operate the data pipeline stack, follow `docker/data-pipeline/AGENTS.md` and
> `docker/data-pipeline/skills/data-pipeline/SKILL.md`. Use the scripts in
> `docker/data-pipeline/scripts/`. Never pass `--yes` without confirmation from the user.

Guidelines for agents:

- Use non-interactive commands: `db.sh query` instead of `db.sh psql`, and pipe
  stdin into `kafka.sh produce`.
- Start diagnosis with `stack.sh status` and `health.sh`, then `stack.sh logs <svc>`.
- Keep output small: `kafka.sh consume <topic> <max>`, `es.sh search <i> <q> <size>`.

## Adding a script

1. Create `scripts/<area>.sh`, starting with a `#` comment block (it becomes the `help` text).
2. `source "$(dirname "$0")/_lib.sh"`, define `cmd_<name>()` functions
   (`cmd_foo_bar` is called as `foo-bar`), end with `dispatch "$@"`.
3. `chmod +x scripts/<area>.sh`, then add it to the table above and to the
   command map in `skills/data-pipeline/SKILL.md` (and `AGENTS.md` if it changes start / checks).
4. Stay compatible with macOS bash 3.2 (no associative arrays, no `mapfile`).
