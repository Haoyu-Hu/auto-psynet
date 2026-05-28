---
command: auto
description: Smart router — turn a natural-language intent into the right /apsy:* command (rule-based, stage-aware).
allowed-tools: Bash, Read, AskUserQuestion, Skill
---

# apsy:auto — router entry

Run the **`apsy:auto`** skill with `$ARGUMENTS` to route a natural-language intent to the right
`/apsy:*` command:
- **HIGH** confidence → auto-dispatch
- **MEDIUM** → confirm the top-2 with `AskUserQuestion`
- **LOW** → show the menu (by pipeline stage), ask the user

Routing is **deterministic** via `bin/apsy-route.py` + `config/routing.json` — no LLM-scored guesswork.
The current `.apsy/state.json` stage gets a small boost so "what's next?" routes sensibly.
