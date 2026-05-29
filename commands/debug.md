---
command: debug
description: Run the current experiment for debugging — launches `bin/apsy-debug.sh` in the background, monitors the boot log, and reports when the server is up. Targets: local | ec2 | stop.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:debug — run / stop the experiment

This command is a thin wrapper around `${CLAUDE_PLUGIN_ROOT}/bin/apsy-debug.sh`. The engine is what
auto-fixes pre-launch state (`.gitignore`, `git init`, `constraints.txt`), verifies Redis + Postgres
reachability, soft-checks `experiment.py` config, prints the runtime-lifecycle reminder, and
launches `psynet debug local`. This command file just orchestrates the invocation + monitoring +
reporting from inside Claude Code.

## STEP 1 — Validate the experiment dir
Confirm the **current working directory** is a PsyNet experiment:
- `experiment.py` and `config.txt` present.
- `.apsy/` exists (if not, create it: `mkdir -p .apsy`).

If `experiment.py` is missing, **stop and route the user to `/apsy:build`** (do not blindly launch
psynet in a non-experiment dir).

## STEP 2 — Resolve target
Parse `$ARGUMENTS`:
- empty / `local` / `--local` → target is `local` (the default — Flask-based auto-reload path; no
  Docker needed).
- `ec2` / `--ec2` → target is `ec2` (still a Phase-1 stub).
- `stop` → forward directly to `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-debug.sh stop` and return.

For `ec2`, run `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-debug.sh ec2` (prints the planned provisioning
sequence) and return.

## STEP 3 — Background launch with nohup (target = local)
PsyNet experiments must outlive this Claude session — the user may close the chat, switch tasks,
and want the server still running. Launch with `nohup` so the process is detached from Claude's
shell, and redirect stdout/stderr to `.apsy/runtime.log` for later monitoring:

```bash
nohup bash "${CLAUDE_PLUGIN_ROOT}/bin/apsy-debug.sh" local > .apsy/runtime.log 2>&1 &
```

(The engine itself writes the launched PID to `.apsy/runtime.pid` for use by the `stop` subcommand,
which we'll surface later.)

## STEP 4 — Monitor the boot
Sleep 5 seconds, then `Read .apsy/runtime.log`. Look for:
- **Success markers** (in this order):
  1. `[apsy-debug] launching:` — the engine got through pre-checks.
  2. `INFO:psynet:Experiment launch complete!` — Flask + the dallinger develop server is up.
  3. A `POST /launch HTTP/1.1" 200` line in the werkzeug log — confirms the launch endpoint
     responded.
- **Failure markers** (handle these immediately):
  - `❌ Pre-launch services not ready` → tell the user to run `bash
    ${CLAUDE_PLUGIN_ROOT}/bin/apsy-services.sh start`.
  - `❌ psynet not installed` → route to `/apsy:install`.
  - `❌ Redis is NOT reachable` / `❌ Postgres is NOT reachable` → same as services-not-ready.
  - `Traceback (most recent call last)` after pre-checks → surface the tail of the log.

Poll up to **60 seconds total** (sleep 5s + Read + grep, up to 12 cycles). Print incremental
status to the user as each marker is detected ("services ✅", "psynet launched ✅", etc.).

## STEP 5 — Report + next steps
When success markers appear, report to the user:

```
✅ psynet debug local is running in the background.
   PID file:  .apsy/runtime.pid
   Log:       .apsy/runtime.log  (tail -f to follow live)
   Dashboard: http://127.0.0.1:5000/dashboard
              user / password — see the log for the generated credentials
              (or check `dashboard_user` / `dashboard_password` in experiment.py)

Next steps:
   - Export data:   /apsy:export                   (redirects to $APSY_PROJECT_DIR/data/<study>/
                                                    when project-dir is set; same as `bash
                                                    bin/apsy-export.sh` outside Claude)
   - Stop cleanly:  /apsy:debug stop               (or bash bin/apsy-debug.sh stop)
   - Hot-reload caveats: edits to Exp class / TrialMaker / module-level imports → restart
     (other edits usually picked up by werkzeug's stat reloader).
```

Then end. The experiment runs independently; the user can return to chat without blocking.

## STEP 6 — Stop semantics
When invoked as `/apsy:debug stop`, run `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-debug.sh stop`. The
engine reads `.apsy/runtime.pid`, sends SIGINT, waits up to 8 seconds, SIGKILLs if still alive,
sweeps orphan workers (gunicorn/flask/dallinger), and removes the PID file. Surface its output.

If no PID file is found, the engine reports that + does a soft probe for matching `psynet debug
local` processes; relay that to the user so they can decide whether to kill them manually.

**This command is debug only — it does NOT enable real recruitment.** Real human data collection
is `/apsy:deploy`, which is gated by **G4** (human approval + IRB attestation + spend cap).
