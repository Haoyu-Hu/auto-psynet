---
command: export
description: Export experiment data from a running `psynet debug local`. Thin wrapper around `bin/apsy-export.sh` that auto-redirects to `$APSY_PROJECT_DIR/data/<study>/` via `--path` (or psynet default `~/psynet-data/export/` if no project dir).
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:export — export experiment data

This is the **export-before-kill** step in the runtime lifecycle. While `psynet debug local` is
running (started by `/apsy:debug`), this command dumps the current experiment state — anonymized
CSVs, source code zip, database zip — to disk so you can verify the data before `Ctrl+C`-ing
psynet. **Run this BEFORE stopping the debug server**; premature `Ctrl+C` may lose pending DB writes.

## STEP 1 — Validate the experiment dir
Confirm cwd is a PsyNet experiment: `experiment.py` present AND (`.apsy/` exists OR
`dallinger_experiment_dir` markers are present). If not, stop and tell the user to `cd` into the
experiment they're debugging.

## STEP 2 — Preflight: is psynet running?
The export needs the live dashboard at `http://localhost:5000` to authenticate + download. Check:
- `.apsy/runtime.pid` exists AND the PID is alive (`kill -0 $(cat .apsy/runtime.pid)`).
  Run this via Bash: `kill -0 $(cat .apsy/runtime.pid 2>/dev/null) 2>/dev/null && echo RUNNING || echo STOPPED`
- OR port 5000 is listening: `ss -tlnp 2>/dev/null | grep ":5000" >/dev/null && echo LISTEN || echo NO`

If neither holds, **stop and instruct**:
*"`psynet debug local` doesn't appear to be running. Start it first with `/apsy:debug`, wait for
`Experiment launch complete!`, then re-run `/apsy:export`."*

## STEP 3 — Invoke the wrapper
Run `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-export.sh $ARGUMENTS` (forward any extra args — common
ones: `--no-source` to skip the source-code zip, `--assets none` to skip media, `--path X` for
explicit destination).

The wrapper:
- If `APSY_PROJECT_DIR` is set and `--path` is NOT in `$ARGUMENTS`, auto-redirects to
  `$APSY_PROJECT_DIR/data/<study>/` (label resolved from `.apsy/state.json` or `experiment.py`).
- Else falls through to `psynet export local` (default `~/psynet-data/export/<study>__...`).

This runs to completion (seconds — not a background task). Capture its stdout/stderr.

## STEP 4 — Report
Parse the wrapper output for:
- `[apsy-export] redirecting export →` (project-dir path) OR `[apsy-export] APSY_PROJECT_DIR not
  set` (psynet default).
- `❯❯ Export complete. You can find your results at: <PATH>` (psynet's success line).
- Any failure (`KeyError: dashboard_password`, connection refused, etc.).

After success, list the export contents to confirm what landed:
```bash
EXPORT_DIR="<the path from 'Export complete' line>"
ls -la "$EXPORT_DIR"           # top-level: anonymous/ regular/ data.zip source_code.zip
ls "$EXPORT_DIR/anonymous/data" 2>/dev/null    # per-class CSVs (e.g. PleasantnessTrial.csv)
```

Report to the user:
```
✅ Export complete.
   Location: <EXPORT_DIR>
   Contents:  anonymous/{data/*.csv, database.zip}, regular/..., data.zip, source_code.zip
   Per-class CSVs: PleasantnessTrial.csv (N rows), StaticNetwork.csv, StaticNode.csv, ...

Next steps:
   - Verify the data matches what you expect (open the CSVs, check N + columns).
   - When ready, kill psynet: /apsy:debug stop
   - Then analyze: /apsy:analyze
```

## Common failure modes (surface verbatim if hit)

- **`KeyError: dashboard_password`** → `experiment.py` doesn't have `dashboard_password` in
  `Exp.config`. Add it (any string) and restart `/apsy:debug`. The 4 experiment templates set
  this by default; if you wrote `experiment.py` by hand or copied from an old demo, this is the
  most common gap.
- **Connection refused on `localhost:5000`** → psynet isn't running. Start it with `/apsy:debug`.
- **`psynet not installed`** from `bin/apsy-export.sh` → run `/apsy:install`.

## ANONYMOUS vs REGULAR

The export writes two trees:
- **`anonymous/`** — privacy-safe (worker IDs hashed, IP/UA stripped). This is what goes into the
  OSF reproducibility package and what `/apsy:analyze` should read.
- **`regular/`** — full data **with PII**. **NEVER share this.** Use locally for debugging only.

The `bin/apsy-repro.sh` packager (called by `/apsy:paper`) bundles `anonymous/` only.
