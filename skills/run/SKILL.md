---
name: run
description: "Autonomous research pipeline — spec in → paper out. Walks FORMULATE → BUILD → PILOT → [DEPLOY] → ANALYZE → PUBLISH honoring autonomy_level; HARD G4 (real deploy) always pauses. Synthetic-only by default; --with-deployment adds the real-human Track B branch."
---

# apsy:run — autonomous research pipeline (spec in → paper out)

> EXECUTION CONTRACT. Loop: ask the engine *what's next*, show the user the reason, dispatch
> (auto-advance if `autopass=true` per autonomy_level; otherwise pause), repeat. **HARD gates are never
> bypassed — G4 always pauses; G7 pauses except in `autonomous` mode where SHIP/iterate are auto** per
> `config/ethics-policy.md` §1.2, §3. Resumable across sessions — state lives in `.apsy/`.

## STEP 1 — Initialize
If a research idea is supplied (`$ARGUMENTS`) and no `.apsy/` exists in cwd, run **`apsy:formulate`
STEP 1** to scaffold `.apsy/` from `config/templates/` and capture the idea. If `.apsy/state.json`
already exists, re-use it (this is how `--resume` works).
Read `state.autonomy_level` (default `supervised`) and `state.run.with_deployment` (default false).

## STEP 2 — The loop
Run `bin/apsy-run.py next` (passing `--with-deployment` if requested):
- **`done: true`** — pipeline finished (PUBLISH complete). Show the paper + repro-package locations and exit.
- **`halted: true`** — show the engine's reason + the fix it suggests (a gate failure, max-iterations
  reached, etc.), then exit. The user resolves and resumes with `/apsy:run --resume`.
- Else: print **`next.skill`** + **`next.reason`** + the current gate.
  - If **`autopass: true`** — invoke the Skill (`apsy:<skill>`). When it returns, re-read state.
  - If **`autopass: false`** — `AskUserQuestion` with options: **Proceed** / **Pause (exit, resumable)**
    / **Abort**. On Proceed → invoke; on Pause → exit (state preserved); on Abort → set state stage
    back/halt and exit.

## STEP 3 — Per-stage skills (already wired)
- FORMULATE → **`apsy:idea`** (full FORMULATE incl. G1 review)
- BUILD → **`apsy:build`** (G2)
- PILOT → **`apsy:pilot`** (G3)
- DEPLOY (only when `--with-deployment`) → **`apsy:deploy`** — **always pauses for human (G4 HARD)**;
  the deploy skill itself runs the full G4 checklist (IRB attestation + spend cap + approval).
- ANALYZE → **`apsy:analyze`** (G5/G6); then **`apsy:iterate`** for the G7 ship/iterate decision.
- PUBLISH → **`apsy:paper`** (write + repro-package).

## STEP 4 — Iteration cap
If G7 = `iterate`, the engine increments the iteration counter and routes back to BUILD. When
`iteration >= max_iterations` (default 1 ⇒ no improvement loop), the engine **halts** for human review;
the user raises `max_iterations` in `.apsy/state.json` to allow more loops.

## STEP 5 — Honesty (non-negotiable)
The full ethics policy applies throughout:
- **G4 NEVER auto-passes** at any autonomy level — real money/people requires explicit human approval +
  IRB attestation + spend cap.
- **Numbers come only from executed runs** — never invent results to advance the loop.
- **Synthetic / LLM-pilot data is labeled in-silico** — never reported as human evidence.
- **AI-involvement disclosure** is required in the generated paper.

**PROHIBITED:** bypassing HARD gates; faking gate passes to make the loop advance; ignoring `autonomy_level`.

**Validation:** before every dispatch, the engine's reason + skill + autopass must be shown to the user.
