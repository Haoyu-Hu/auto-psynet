---
command: debug
description: Run the current experiment for debugging — pick local (psynet debug local) or a provisioned EC2 instance.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:debug — run the experiment (local or EC2)

1. Confirm the current directory is a PsyNet experiment (`experiment.py` + `config.txt`) with an `.apsy/`
   state dir. If not, tell the user to scaffold first (`/apsy:build`) and stop.
2. Use `AskUserQuestion` to choose the **target**:
   - **local** — `bin/apsy-debug.sh local` → `psynet debug local`. **The default path (no `--docker`)
     uses dallinger's Flask-based develop server + auto-reload — does NOT need Docker.** Needs only
     a working Python env with psynet/dallinger installed and (typically) a local PostgreSQL.
     Add `--docker` only if you want the containerized path; add `--legacy` to fall back to the
     older `dallinger debug` path.
   - **ec2** — `bin/apsy-debug.sh ec2` → provision/refresh a Dallinger EC2 instance
     (`{username}.{study}.{host}`, region + `m7i.{N}xlarge` from config) and run there.
3. Run the chosen target via the engine, surface the participant URL + logs, and append the action to
   `.apsy/deployment-log.md`.

## **CRITICAL — runtime lifecycle (always warn the user before launching)**

PsyNet experiments **have no stop button or signal**. Once `psynet debug local` is up, it keeps
running indefinitely — even after the recruitment cap is reached. The only way to stop it is
**`Ctrl+C` in the terminal that started it**. Closing the browser / hitting "Done" does NOT kill
the server.

**Required workflow before `Ctrl+C`:**
1. Run **`bash bin/apsy-export.sh`** in a separate shell. (If `APSY_PROJECT_DIR` is set, the
   wrapper redirects the export to `<APSY_PROJECT_DIR>/data/<study>/` via `--path`. Otherwise it
   falls through to plain `psynet export local` → `~/psynet-data/export/<study>__mode=debug__.../`.)
2. Verify the export contents (CSVs under `anonymous/data/` are what you need; `source_code.zip`
   archives the experiment.py).
3. Only then `Ctrl+C` the debug terminal to destroy.

Premature `Ctrl+C` may lose pending DB writes that weren't flushed.

**Hot-reload behavior (verified 2026-05-28 — two-layered mechanism):**
- werkzeug's stat reloader **fires on every file change** (the log shows `Detected change …
  reloading` for ALL edits).
- BUT dallinger's worker subprocesses (gunicorn workers, the experiment_server process) **do not
  auto-re-import** the Exp class — they keep the OLD class objects.

So edits that change CLASS STRUCTURE may LOOK reloaded yet leave the workers stale. **Restart IS
required** for:
- the top-level `Exp` class (config dict, label, top-level attributes)
- any `TrialMaker` subclass
- module-level imported classes used by the timeline

Edits to method bodies, literal strings, comments, `bot_response` lambdas, `time_estimate` values
usually hot-reload cleanly. **When in doubt, restart.** (Concrete failure observed: adding a key
to Exp.config → werkzeug reloaded, but `/dashboard/config` returned `KeyError` because workers
cached the old config.)

**This is debug only — it does NOT enable real recruitment.** Real human data collection is `/apsy:deploy`,
which is gated by **G4** (human approval + IRB attestation + spend cap).
