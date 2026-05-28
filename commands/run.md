---
command: run
description: Autonomous research pipeline — idea → paper. Walks the full lifecycle honoring autonomy_level; G4 (real deploy) is HARD at every level.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Task, Skill
---

# apsy:run — autonomous research pipeline

Run the **`apsy:run`** skill with `$ARGUMENTS` — a research idea, or `--resume` to continue an
existing experiment (state is read from `.apsy/state.json`).

Autonomy comes from `.apsy/state.json` `autonomy_level` (default **`supervised`**):
- **supervised** — pause for human at every gate.
- **semi_autonomous** — auto-advance soft gates (G1/G2/G3/G5/G6); pause at **G4** (always) + **G7**.
- **autonomous** — auto soft + G7; **G4 ALWAYS PAUSES** (real money / real people — ethics policy §1.2, §3).

Synthetic-only by default — FORMULATE → BUILD → LLM-PILOT → synthetic ANALYZE → PUBLISH (in-silico,
labeled). Pass **`--with-deployment`** to add the real-human branch; G4 still hard-blocks until
approval + IRB attestation + spend cap. The run is **resumable** — re-running `/apsy:run` picks up
from the current state.
