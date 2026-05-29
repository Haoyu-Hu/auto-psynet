# Auto-PsyNet (`apsy`)

A Claude Code plugin that automates the lifecycle of online **behavioral experiments** built on
[PsyNet](https://psynetdev.gitlab.io/PsyNet/): a raw research idea → a verified, preregistered plan →
working PsyNet experiment code → **LLM-pilot** and human deployment → analysis & iteration → a
publication-ready paper. Experimental subjects can be **humans and/or LLM agents**.

> **Start here:** run **`/apsy:setup`** — it picks the Python interpreter (optionally creates a
> managed venv at `~/.auto-psynet/venv`), runs the dependency + version check (`bin/apsy-check.sh`),
> offers `/apsy:install` if `psynet`/`dallinger`/the stats stack are missing, asks for a **project
> directory** where new experiments will live (`/apsy:project-dir` later changes it), then configures
> the LLM-participant backend, username, AWS region, base domain, and consent default. A
> SessionStart hook nudges you to setup on first run; all other `/apsy:*` commands assume setup is
> complete.

> **Status: Phase 0 (foundations).** The plugin skeleton, manifest, operating policy, command surface,
> the deterministic engine, the LLM-participant driver, the 5-stage pipeline state machine, the PsyNet
> knowledge pack (8 paradigm recipes + 8 cross-cutting), and the analysis stack are all in place.
> Skills and paradigm recipes continue to be filled in per [`project-plan/05-roadmap.md`](project-plan/05-roadmap.md);
> see [`project-plan/`](project-plan/) for the full design.

## Pipeline

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   idea→plan     experiment code   LLM-pilot → humans      data → findings    paper
                         ╰────────────── iterate ──────────────╯
```

`/apsy:run` walks the whole pipeline autonomously (honoring `autonomy_level`; **G4 is HARD** at every
level — real human deploy always requires explicit human approval + IRB attestation + spend cap).
`/apsy:auto` is a smart router that turns a free-text intent into the right `/apsy:*` command.

## Command surface

### Setup & maintenance

| Command | Purpose |
|---------|---------|
| `/apsy:setup` | First-run config — Python interpreter / managed venv, project directory, LLM-participant backend, username/server prefix, AWS, base domain, consent default. |
| `/apsy:install` | Auto-install essential deps (`psynet` + `dallinger` + optional stats stack); offers managed venv at `~/.auto-psynet/venv`. |
| `/apsy:update` | Upgrade PsyNet / Dallinger; reuses the install engine via `--upgrade`. |
| `/apsy:project-dir` | Set or inspect `APSY_PROJECT_DIR`. Optionally symlinks `~/psynet-data` → `$APSY_PROJECT_DIR/data` via `bin/apsy-link-data.sh` (5-case safety table; refuses if `~/psynet-data` has existing content). |
| `/apsy:services` | Start / stop / status of Redis + PostgreSQL for `psynet debug local`. Auto-detects binaries, initdb's pg, creates dallinger user + db. Idempotent. |
| `/apsy:doctor` | Environment diagnostics — interpreter, essential deps, Redis + Postgres reachability, LLM keys, AWS, project-dir, config. |
| `/apsy:status` | Where the current experiment stands (reads `<experiment>/.apsy/state.json`) + the next action. |

### Pipeline (one command per stage)

| Command | Stage | Purpose |
|---------|-------|---------|
| `/apsy:idea` | FORMULATE | Idea → verified, preregistered plan (gate G1). Scaffolds into `$APSY_PROJECT_DIR/<study>/` when project-dir is set. |
| `/apsy:build` | BUILD | Generate the PsyNet experiment from the locked plan; scaffold + implement + bot-test to G2. |
| `/apsy:pilot` | PILOT | Run the experiment with LLM-agent participants — validate pipeline + analysis on synthetic data (gate G3). No human spend. |
| `/apsy:debug` | — | nohup-launch `psynet debug local` via `bin/apsy-debug.sh` (auto-fixes `.gitignore`/`git init`/`constraints.txt`, checks services, prints lifecycle reminder). `/apsy:debug stop` cleanly SIGINT's via `.apsy/runtime.pid`. |
| `/apsy:export` | — | Export experiment data while psynet is live. Preflights for runtime; wraps `bin/apsy-export.sh` (redirects to `$APSY_PROJECT_DIR/data/<study>/` via `--path` when project-dir is set). |
| `/apsy:deploy` | DEPLOY | Deploy for **real human** data (gate G4) + recruit. HARD gate at every autonomy level. |
| `/apsy:analyze` | ANALYZE | Run the preregistered analysis on exported data, report effects; iterate or ship (gates G5/G6/G7). |
| `/apsy:paper` | PUBLISH | Assemble the paper draft (Methods from pipeline, Results from analysis) + an OSF-ready reproducibility package. |

### Autonomy & routing

| Command | Purpose |
|---------|---------|
| `/apsy:run` | Autonomous pipeline — idea → paper. Honors `autonomy_level`; **G4 always HARD**. |
| `/apsy:auto` | Smart router — natural-language intent → the right `/apsy:*` command (rule-based, stage-aware). |

### Extension

| Command | Purpose |
|---------|---------|
| `/apsy:add-recipe` | Add a new file under `skills/psynet/psynet-function/` (a new paradigm or cross-cutting capability) and auto-update the parent index. |

### Per-experiment configuration

| Command | Purpose |
|---------|---------|
| `/apsy:consent` | Configure the consent form (default: PsyNet `MainConsent`). |
| `/apsy:prolific` · `/apsy:lucid` · `/apsy:mturk` | Configure the recruiter for this experiment. |
| `/apsy:region` · `/apsy:type` | Override AWS region (default `us-east-1`) / EC2 instance type (default auto-sized `m7i.{N}xlarge`). |

## Install (development)

```bash
# from a Claude Code session, with this repo checked out:
/plugin marketplace add /work/hdd/bgmm/hhu4/auto-psynet
/plugin install apsy@auto-psynet

# inside Claude Code:
/apsy:setup           # first-run config (interpreter, project-dir, LLM backend, AWS, ...)
/apsy:install         # install psynet + dallinger (offers a managed venv on first run)
/apsy:project-dir     # set APSY_PROJECT_DIR — the consistent root for new experiments
/apsy:doctor          # verify the runtime (interpreter, deps, Redis, Postgres, project-dir)
```

### Project organization (`APSY_PROJECT_DIR`)

By default, `/apsy:idea` scaffolds new experiments in the current working directory — fine for
one-off work, inconsistent across sessions. Setting `APSY_PROJECT_DIR` once (via `/apsy:setup` or
later via `/apsy:project-dir`) gives every new study a home under the same root:

```
~/research/apsy-experiments/                ← $APSY_PROJECT_DIR
├── pleasantness-rating/                    ← created by /apsy:idea
│   ├── experiment.py  config.txt  requirements.txt  constraints.txt
│   ├── .gitignore                          ← auto-created by bin/apsy-debug.sh
│   └── .apsy/                              ← per-experiment state + reports + paper draft
├── color-gsp/
└── data/                                   ← (optional) symlinked from ~/psynet-data
    ├── export/<study>__mode=debug__.../    ← from `bash bin/apsy-export.sh`
    ├── assets/  launch-data/  artifacts/   ← PsyNet's other hardcoded dirs
```

The data redirect is two-pronged: `bin/apsy-export.sh` auto-adds `--path
$APSY_PROJECT_DIR/data/<study>` to `psynet export local`; the optional `~/psynet-data` symlink
(offered by `/apsy:project-dir`) redirects PsyNet's hardcoded `assets`/`launch-data`/`artifacts`
paths transparently.

### Running an experiment locally (the slash-command flow)

```bash
cd ~/research/apsy-experiments/pleasantness-rating
/apsy:services start    # Redis + Postgres, with dallinger user + db (idempotent)
/apsy:debug             # auto-fixes pre-launch state + nohup-launches psynet
                         #   → reports "Experiment launch complete!" + dashboard URL
                         #   → process survives Claude session ending
/apsy:export            # exports data into $APSY_PROJECT_DIR/data/<study>/
/apsy:debug stop        # SIGINTs via .apsy/runtime.pid; sweeps orphan workers
/apsy:services stop     # services down (state preserved on disk)
```

Each slash command wraps a `bin/apsy-*` engine that's also usable standalone in any shell (no
Claude needed). The slash commands add preflight + monitoring + reporting on top.

**What `bin/apsy-debug.sh` does** (auto-fixes pre-launch state):
- `.gitignore` (standard PsyNet patterns) — created if missing
- `git init` + initial commit — required by psynet's git introspection
- `constraints.txt` (via `psynet generate-constraints`) — required by `_pre_launch`
- PATH hygiene — venv `bin/` ahead of system Python (else `flask` resolves wrong)
- Hard checks: Redis reachable, PostgreSQL reachable → suggests `/apsy:services start` on fail
- Soft checks: `recruiter="generic"` + `dashboard_password` in `Exp.config`
- Lifecycle reminder: hot-reload caveats + export-before-stop workflow
- nohup-detached launch + PID file → process survives session ending; `stop` subcommand kills cleanly

**Runtime services** (Redis at `localhost:6379` + PostgreSQL at `localhost:5432` with a `dallinger`
user + db) are required for `psynet debug local`. `/apsy:services start` handles everything:
detects binaries (PATH or common conda paths), `initdb`'s the pg data dir on first run,
auto-creates the `dallinger` superuser + database, and is idempotent on already-running.

Install priority if the binaries aren't on your box:

```
1. System: apt install redis-server postgresql (Ubuntu)  ·  brew install redis postgresql@14 (macOS)
2. conda-forge: conda install -c conda-forge redis-server postgresql (no-root fallback)
3. Source compile (last resort)
```

> `pip`/`uv` cannot install Redis or PostgreSQL — they're server binaries, not Python packages.
> The default `psynet debug local` path does NOT need Docker.

### Export-before-stop workflow

PsyNet experiments have **no in-experiment stop signal** — `psynet debug local` runs indefinitely.
Stop via `/apsy:debug stop` (or `Ctrl+C` if running foreground). Before stopping:

```bash
/apsy:export                        # exports the live data
# → If APSY_PROJECT_DIR is set, redirects to <project-dir>/data/<study>/
# → Otherwise falls through to psynet's default ~/psynet-data/export/<study>__.../
# → Bundle: anonymous/data/*.csv (PRIVACY-SAFE) + regular/data/... (HAS PII) +
#           source_code.zip + database.zip
# Verify, THEN:
/apsy:debug stop                    # clean SIGINT + sweep orphans + remove PID file
```

`anonymous/` is what `bin/apsy-repro.sh` (called by `/apsy:paper`) bundles into the OSF package.
`regular/` has PII and **must never** be shared.

### Hot-reload behavior (verified)

werkzeug's stat reloader fires on **every** file change, but dallinger's worker subprocesses don't
auto-re-import. So edits that change **class structure** may look reloaded yet leave workers stale.

| Edit category | Verdict |
|---|---|
| Comments / strings / `bot_response` / `time_estimate` values | werkzeug reload sufficient |
| `Exp` class config / `TrialMaker` / module-level imports | **restart** `bin/apsy-debug.sh local` |

### Python interpreter / virtualenv

PsyNet pulls a large dependency tree (Dallinger, Postgres bindings, Selenium, ~70 packages), so the
plugin installs into an explicit Python interpreter rather than wherever `pip` happens to write. The
resolver in [`bin/apsy-common.sh`](bin/apsy-common.sh) picks the interpreter via this priority chain:

```
--python PATH  >  $VIRTUAL_ENV/bin/python  >  $APSY_PYTHON (~/.auto-psynet/config)  >  python3 from PATH
```

- **First run (no venv active):** `/apsy:install` offers to create a **managed venv** at
  `~/.auto-psynet/venv/` and records `APSY_PYTHON` in `~/.auto-psynet/config` — that becomes the
  canonical "apsy python" for every subsequent `/apsy:install`, `/apsy:update`, and `/apsy:doctor`.
  Run `bin/apsy-install.sh --create-venv` to do this non-interactively.
- **Conda / poetry / uv users:** point at your interpreter via `APSY_PYTHON=/path/to/python` (set in
  `~/.auto-psynet/config` or the environment) or pass `--python /path/to/python` to any engine call.
- **Active venv in this shell:** `$VIRTUAL_ENV` wins over `$APSY_PYTHON` for that session.
- **No venv, no `APSY_PYTHON`:** the engine falls back to `python3` from PATH and adds `--user` when
  site-packages isn't writable. It **never** silently passes `--break-system-packages`.

Run `/apsy:doctor` to see exactly which interpreter the plugin will use, and whether `psynet` /
`dallinger` / the stats stack are importable from it.

## Optional: MCP server

For non-Claude clients (Cursor, Codex, custom automation), a thin opt-in MCP server exposes six
engine tools — `apsy_status`, `apsy_doctor`, `apsy_route`, `apsy_next`, `apsy_power`,
`apsy_data_quality`. See [`mcp-server/README.md`](mcp-server/README.md). The server is stdlib-only
Python and is **off by default** (`APSY_MCP_ENABLED=true` to enable).

## Layout

```
.claude-plugin/   plugin + marketplace manifests (name locked to "apsy")
commands/         slash commands (24)
skills/           SKILL.md execution contracts (32) — incl. skills/psynet/ knowledge hub
agents/           expert personas + routing (config.yaml) — 9 personas
hooks/            SessionStart + PreToolUse lifecycle hooks (first-run nudge, lint, G4 spend gate)
bin/              the deterministic engine (23 helpers — apsy_resolve_python interpreter resolver,
                  apsy-services.sh runtime services, apsy-debug.sh (auto-fix + nohup launch +
                  stop subcommand), apsy-export.sh (--path redirect), apsy-link-data.sh (~/psynet-
                  data symlink helper), apsy-check.sh, apsy-pilot.sh + apsy_llm_participant.py, …)
config/           ethics-policy, gates G1-G7, pipeline, affinity, blind-spots, templates
mcp-server/       optional stdlib MCP server (off by default)
tests/            assembly + behavior tests
project-plan/     the full design (read this first)
```

Built on [PsyNet](https://gitlab.com/PsyNetDev/PsyNet) / [Dallinger](https://github.com/Dallinger/Dallinger).
Ethics & integrity policy: [`config/ethics-policy.md`](config/ethics-policy.md).
