---
command: build
description: Generate the PsyNet experiment from a G1-verified plan — scaffold, implement, wire timeline, bot-test to G2.
allowed-tools: Bash, Read, Write, Edit, Task, Skill
---

# apsy:build — BUILD (verified plan → working PsyNet experiment)

Orchestrate the BUILD stage. **Requires gate G1 = pass** (run `/apsy:idea` first). Run the skills in
order, honoring the autonomy level in `.apsy/state.json`:

1. **`apsy:scaffold`** — lay down `experiment.py` (paradigm template) + `config.txt` + `requirements.txt`
   + PsyNet boilerplate.
2. **`apsy:implement-paradigm`** — fill the `Trial`/`Node`/`TrialMaker` code from the paradigm recipe
   (`skills/psynet/psynet-function/<paradigm>.md`, via the `apsy:psynet` index) + the plan.
3. **`apsy:generate-stimuli`** — only if stimuli are non-trivial / media / generated.
4. **`apsy:wire-timeline`** — consent → instructions → prescreens → demography → trial maker(s) → debrief.
5. **`apsy:test-experiment`** — gate **G2**: run `psynet test local` until green.

On **G2 PASS**, `state.json` advances to `stage: PILOT` (next: `/apsy:pilot`). G2 needs the PsyNet
runtime — if it's absent, generate the code, then run `/apsy:doctor` and install psynet (or use the EC2
runtime) before G2. **Never mark G2 passed without an actual green `psynet test local`** (`config/ethics-policy.md`).
