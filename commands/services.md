---
command: services
description: Start / stop / status of the runtime services (Redis + PostgreSQL) that `psynet debug local` requires. Thin wrapper around `bin/apsy-services.sh` that surfaces the engine's idempotent operations + auto-setup of the dallinger user + database. Subcommands: status (default) · start · stop · restart.
allowed-tools: Bash, AskUserQuestion
---

# apsy:services — manage Redis + PostgreSQL for local debug

`psynet debug local` needs **Redis at `localhost:6379`** (`_pre_launch` checks all 3 debug paths)
+ **PostgreSQL at `localhost:5432`** with a `dallinger` superuser and `dallinger` database. This
command is the orchestrated entry point to `bin/apsy-services.sh`, which handles all of that
with idempotent start/stop/status semantics.

## STEP 1 — Resolve subcommand
Parse `$ARGUMENTS`:
- empty / `status` → `status` (default; non-destructive — just reports what's running)
- `start [--redis-only|--pg-only]` → start the services (idempotent on already-running)
- `stop  [--redis-only|--pg-only]` → stop them (idempotent on already-stopped)
- `restart` → stop + start in sequence

## STEP 2 — Invoke the engine
Run `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-services.sh $ARGUMENTS`. The engine:
- Detects binaries via 3 tiers — `APSY_*_BIN` env > PATH > common conda paths
  (`~/miniconda3/bin`, `~/anaconda3/bin`, `/opt/conda/bin`, `/opt/conda/envs/apsy-services/bin`,
  `/tmp/apsy-services/bin`).
- State dir defaults to `~/.auto-psynet/services/` (override via `APSY_SERVICES_DIR`):
  `redis/` (dump.rdb + pid) and `pg/` (postgres data dir + log).
- On first `start`: `initdb`'s the pg data dir, starts both, **auto-creates the `dallinger`
  superuser + `dallinger` database**.
- Subsequent `start` calls: detect "already running" and no-op.
- `stop`: cleanly shuts down; state preserved on disk (so next `start` reuses, no re-`initdb`).

Capture stdout/stderr — the engine's output is already well-formatted (`  ✅ ... started on
localhost:6379  (data: ...)` and similar).

## STEP 3 — Report + next steps

After **start** (whether first-time or idempotent re-start):
```
✅ Services up:
   - Redis    on localhost:6379
   - Postgres on localhost:5432  (dallinger user + database ready)
Next:  /apsy:debug   (launch psynet debug local on the current experiment)
```

After **stop**:
```
✅ Services down. (Data preserved at ~/.auto-psynet/services/ — restart anytime via /apsy:services start.)
```

After **status** (the engine prints binary paths + ports + running state + dallinger-db existence
already; relay verbatim).

After **restart**: same as start.

## Common failure modes (surface verbatim if hit)
- **`❌ redis-server binary not found`** → engine prints the install priority list (apt/brew/dnf
  first; conda-forge fallback for HPC-no-root; pip/uv can't install it). Repeat the priority list
  to the user.
- **`❌ pg_ctl not found`** → same pattern for PostgreSQL.
- **`❌ initdb not found`** → first-time pg setup needs initdb; install postgresql (which bundles
  initdb).
- **`❌ postgres start failed`** → the engine tails `~/.auto-psynet/services/pg.log` — relay it.

## Env-var overrides (for non-standard setups)
| Var | Purpose |
|---|---|
| `APSY_SERVICES_DIR` | state-dir root (default `~/.auto-psynet/services`) |
| `APSY_REDIS_BIN` / `APSY_REDIS_CLI_BIN` | explicit paths to redis-server / redis-cli |
| `APSY_PG_CTL_BIN` / `APSY_INITDB_BIN` / `APSY_PG_ISREADY_BIN` / `APSY_PSQL_BIN` | explicit paths for the postgres tooling |
| `REDIS_HOST` / `REDIS_PORT` / `PGHOST` / `PGPORT` | endpoint overrides |

The engine is **idempotent and reentrant** — safe to run repeatedly. No state is lost across stop.
