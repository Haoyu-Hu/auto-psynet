# PsyNet function: CLI & deployment

**CLI (`psynet ...`):** `debug local` (dev); `debug ssh|heroku` (cloud test, recruitment OFF);
`deploy ssh|heroku` (real); `export local|ssh|heroku`; `test local` (bots → gate G2); `estimate`;
`prepare`; `update-scripts` (regenerate boilerplate); `generate-constraints`; `experiment-variables`;
`db`; `lucid ...`; `translate`.

**`psynet debug local` has THREE paths** (verified against `materials/psynet/psynet/command_line.py:debug__local`):
- **default → `_debug_auto_reload`** — uses `dallinger.command_line.develop.debug` (Flask-based, native
  process; no Docker). Supports **hot-reload** of file edits while the server is running.
- `--docker` → `_debug_docker` (containerized; needs Docker daemon).
- `--legacy` → `_debug_legacy` (the older `dallinger debug` path; useful if the auto-reload path fails).

**Infra needs depend on the path.** Real deploy needs Docker + Postgres + Redis + worker/clock + a
public web endpoint. **Local debug WITHOUT Docker needs (verified by direct test 2026-05-28):**
- **Native Redis** at `localhost:6379` — used by `_pre_launch` in ALL three paths (auto-reload,
  legacy, docker).
- **Native PostgreSQL** at `localhost:5432` with a `dallinger` superuser + `dallinger` database.
- **DATABASE_URL** + **REDIS_URL** env vars (defaults usually fine if services are on local default ports).

**Install priority for Redis + PostgreSQL** (`pip`/`uv` are NOT options — these are server binaries,
not Python packages):
1. **System package manager** — primary on most dev boxes (~1 min, lightest):
   - Debian/Ubuntu: `sudo apt install redis-server postgresql`
   - macOS: `brew install redis postgresql@14`
   - RHEL/Fedora: `sudo dnf install redis postgresql-server`
2. **conda-forge** — fallback when no root (HPC, locked-down machines): `conda install -c
   conda-forge redis-server postgresql`. Heavier than apt/brew (the conda env adds ~hundreds of
   MB) but works without root.
3. **Build from source** — last resort. Redis source builds in ~30s on a small box; Postgres takes
   minutes and is rarely worth it.

**Service bootstrap** (works regardless of how you got the binaries):
```bash
# Redis (no config needed for local debug)
redis-server --daemonize yes

# PostgreSQL — initdb a data dir, start, create the dallinger user + db
initdb -D ~/apsy-pg --auth=trust
pg_ctl -D ~/apsy-pg -l ~/apsy-pg.log start
psql -U postgres -c "CREATE USER dallinger SUPERUSER; CREATE DATABASE dallinger OWNER dallinger"
```

**Experiment-directory pre-launch requirements** (psynet's `_pre_launch` calls `run_pre_checks`):
- `experiment.py` + `config.txt` + `requirements.txt` present.
- **`constraints.txt`** present (generate via `psynet generate-constraints` — produces a uv-locked
  file from requirements.txt + dallinger's dev-requirements URL).
- **`.gitignore`** present (psynet rejects directories without one).
- **The dir is a `git init`'d repository** (psynet does git introspection during launch).
- **`PATH`** has the psynet venv's `bin/` BEFORE the system Python (otherwise `flask`/`gunicorn`
  resolve to the wrong interpreter and the server fails with `ModuleNotFoundError: No module named
  'gevent'`).

**Recruiters (`config.txt` `recruiter =` / `Exp.config`):** `generic` (manual link; **dev default —
required for `psynet debug local` unless you set the panel-specific config**), `hotair` (test),
`prolific` (needs `prolific_workspace` config; will 500 on `/launch` without it), `mturk`,
`lucid-recruiter` (global panels), `cap-recruiter`. Adaptive recruitment via `recruit_mode`
(`n_participants` / `n_trials`) + `initial_recruitment_size`.

**Other config Exp.config must include for `psynet debug local` to fully exercise the workflow:**
- **`dashboard_password`** — needed by `psynet export local` (and the dashboard auth in general).
  Without it, the server logs a generated random password at boot but `psynet export local` from a
  separate shell fails with `KeyError: dashboard_password`. Set explicitly in the Exp config dict
  so it's reproducible.
- **`dashboard_user`** — defaults to `admin`; safe to leave or set explicitly.

**Runtime lifecycle (critical operational knowledge):**
- **Experiments have no stop signal.** Once a `psynet debug local` (or any psynet) process is up,
  it keeps running indefinitely — even after the recruitment cap is reached. The recruiter and
  the experiment server are independent components.
- **The only way to stop and destroy it is `Ctrl+C` in the terminal that started it.** Closing the
  browser or hitting "Done" in the UI does NOT kill the server.
- **Workflow:** before `Ctrl+C`, run **`psynet export local`** in a separate shell and verify the
  export contains what you need. Premature `Ctrl+C` may lose pending DB writes.
- **Hot-reload (verified 2026-05-28 against psynet 13.2 / dallinger 12.2):** more nuanced than
  "some edits do/don't reload" — the mechanism is two-layered:
  - **Layer 1: werkzeug's stat reloader fires on EVERY file change.** Tested 8 categorized edits
    to experiment.py (comments, InfoPage strings, bot_response lambdas, Trial.time_estimate,
    Exp.label, Exp.config keys, show_trial method bodies, module-level imports). Log showed
    `Detected change in '/tmp/dallinger_develop/experiment.py', reloading` + `Restarting with stat`
    for ALL 8. Server stayed responsive throughout.
  - **Layer 2: dallinger's worker/auxiliary subprocesses do NOT auto-re-import.** They hold the
    OLD Exp class objects after a reload. **Concrete failure observed:** adding a new key to
    Exp.config (e.g. `"T6_test_key": "added"`) → `GET /dashboard/config` returned
    `KeyError: 'T6_test_key'` even though werkzeug had reloaded the file. The dashboard code
    references the live Exp.config (which has the key) but reads it against a stale cached dict
    in a worker that doesn't.
  - **Practical rule:** edits that change CLASS STRUCTURE (Exp class config dict, Trial /
    TrialMaker class attributes, module-level imports) → **restart `psynet debug local`** even
    though werkzeug "appears" to reload, because workers don't see the new class. Edits to
    method bodies / literal strings / comments / bot_response lambdas → werkzeug reload usually
    sufficient. **When in doubt, restart.**

**How `apsy` wraps these:** `apsy-scaffold.sh` (→ `update-scripts`), `apsy-test.sh` (→ `test local`, G2),
`apsy-debug.sh` (local | ec2), `apsy-deploy.sh` (G4 gate → `deploy`), `apsy-export.sh` (→ `export`),
`apsy-pilot.sh` (LLM-participant `test local`).

**Gotchas:** pin the `psynet` version (`requirements.txt`); local debug does NOT necessarily need
Docker (default is the Flask-based auto-reload path) but DOES need native Redis + PostgreSQL — they
are NOT optional; the **`ec2`** backend (Dallinger provisioning) is for cloud testing + real
deploy; real `deploy`/recruit is gated by **G4** (`config/ethics-policy.md`); **never** trust the
experiment to stop on its own — Ctrl+C is the only way out.

**Verified-in-practice debug sequence (2026-05-28; no Docker required):**
```bash
# (one time) native services — pick ONE of:
#   apt:    sudo apt install redis-server postgresql
#   brew:   brew install redis postgresql@14
#   conda:  conda create -y -p ~/apsy-services -c conda-forge redis-server postgresql
# Then start them (service paths shown for conda; system installs use systemctl or service):
redis-server --daemonize yes
initdb -D ~/apsy-pg --auth=trust
pg_ctl -D ~/apsy-pg -l ~/apsy-pg.log start
psql -U postgres -c "CREATE USER dallinger SUPERUSER; CREATE DATABASE dallinger OWNER dallinger"

# (per experiment) pre-launch fixups
psynet generate-constraints     # → constraints.txt
test -f .gitignore || echo "data/\nexport/\n*.pyc\n__pycache__/" > .gitignore
test -d .git || (git init && git add . && git commit -m "init")

# (per launch) make sure venv is in front
export PATH=/path/to/apsy-venv/bin:~/apsy-services/bin:$PATH
psynet debug local              # auto-reload mode (default; no Docker)
# In another shell: psynet export local → ~/PsyNet-data/export/<app>/
# Verify the export, THEN Ctrl+C the debug-local shell to destroy.
```
