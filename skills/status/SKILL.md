---
name: status
description: "Report where the current Auto-PsyNet experiment stands — use when the user says 'apsy status', 'where am I', 'what's next', or resumes work. Reads <experiment>/.apsy/state.json."
---

# apsy:status — experiment status & resume point

> EXECUTION CONTRACT. Read-only. The per-experiment `.apsy/` directory is the source of truth.

## STEP 1 — Locate the experiment
Use `bin/apsy-state.sh find` to locate the nearest `.apsy/` directory (cwd or an ancestor).
- **If none is found:** report that the current directory is not an Auto-PsyNet experiment, and suggest
  `/apsy:idea "<your idea>"` to start one. Stop here.

## STEP 2 — Read state
Read `.apsy/state.json` (schema in `config/templates/state.json`). Extract: `stage`, `iteration`,
`autonomy_level`, per-gate `gate_statuses`, `deploy_target`, cumulative `spend`, and `next_action`.

## STEP 3 — Report
Show a compact summary:
- **Stage / iteration** and the pipeline position (`FORMULATE → BUILD → PILOT&DEPLOY → ANALYZE → PUBLISH`).
- **Gate statuses** (G1–G7) with ✅ / ⚠️ / ❌ / — (not reached).
- **Deploy target** + **spend so far** vs the cap.
- The recorded **next action**, and the tail of `.apsy/iteration-log.md` for recent context.

Keep it scannable. Do not modify any file.
