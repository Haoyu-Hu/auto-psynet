---
name: auto
description: "Smart router — single natural-language entry point that picks the right /apsy:* command. Use when the user types /apsy:auto, says 'just do X', or has a request that doesn't obviously map to one specific /apsy:* command. Routing is deterministic + transparent — no LLM-scored guesswork."
---

# apsy:auto — smart router (natural language → `/apsy:*` command)

> EXECUTION CONTRACT. Deterministic + transparent: a **rule-based** router (`bin/apsy-route.py` +
> `config/routing.json`) does the matching; the engine reports its reasons. Always show the user the
> chosen route and let them override before dispatch.

## STEP 1 — Get the query
`$ARGUMENTS` is the user's intent. If empty, ask once via `AskUserQuestion` ("What do you want to do?")
before continuing.

## STEP 2 — Route
Run `bin/apsy-route.py "<query>"` — it auto-detects the nearest `.apsy/state.json` to apply a
stage-aware boost (the current stage's next-action gets a bump). Parse the JSON: `confidence`,
`recommended_command`, `top` (each with `score` + `reasons`), `stage`.

## STEP 3 — Decide by confidence
- **HIGH** — tell the user *"Routing to `/apsy:<cmd>` because <top reasons>"*, then **invoke** the Skill
  `apsy:<cmd>` (or the matching one for the config commands like `prolific`/`region`/`type`).
- **MEDIUM** — present the top-2 candidates with `AskUserQuestion` (one option per candidate, plus
  "Other" for free text). Dispatch the chosen one.
- **LOW** — show the menu grouped by stage (FORMULATE / BUILD / PILOT / ANALYZE / PUBLISH /
  config-setters), ask `AskUserQuestion` which to run. **Never auto-dispatch on LOW.**

## STEP 4 — Dispatch + record
Invoke the chosen `apsy:<cmd>` skill via the Skill tool. If we're inside an experiment directory,
append a one-line routing record (query + chosen command + confidence) to `.apsy/decisions.md` for the
audit trail.

**PROHIBITED:** silently routing on LOW confidence; routing to the G4-gated `deploy` without going
through that skill's full G4 gate; inventing commands not in `config/routing.json`.

**Validation gate:** always print the chosen command (and the router's reasons) *before* invoking; never
auto-dispatch on LOW.
