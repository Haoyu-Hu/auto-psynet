---
name: scaffold
description: "BUILD step 1 — scaffold the PsyNet experiment project from the verified plan: experiment.py (from the paradigm template), config.txt, requirements.txt, and PsyNet boilerplate. Requires a G1-verified plan."
---

# apsy:scaffold — create the PsyNet project skeleton

> EXECUTION CONTRACT. Apply the **psynet-engineer** persona. **Requires gate G1 = pass.**

## STEP 1 — Preconditions
Read `.apsy/state.json`: require `gate_statuses.G1 == pass` and a non-empty `paradigm`. If not, stop and
point the user to `/apsy:idea`. **Do not scaffold an unverified plan.**

## STEP 2 — Experiment directory
The experiment lives in the directory that holds `.apsy/` (usually the cwd). Confirm the path.

## STEP 3 — Scaffold
Run `bin/apsy-scaffold.sh <dir> <paradigm>`. It writes `experiment.py` (from
`config/templates/experiment_<paradigm>.py.tmpl`), `config.txt`, `requirements.txt`, and runs
`psynet update-scripts` for boilerplate (or notes that psynet is absent). Pin `requirements.txt` to the
PsyNet version that `/apsy:doctor` validated.

## STEP 4 — Record
`bin/apsy-state.sh set stage BUILD`; `set next_action "run apsy:implement-paradigm"`.

**Validation gate:** `experiment.py`, `config.txt`, and `requirements.txt` exist in the experiment dir.
