---
name: llm-pilot
description: "PILOT gate G3 — run the experiment with LLM-agent participants to validate the pipeline end-to-end, produce synthetic data, exercise the analysis pipeline, and sanity-check that the task is doable. No human spend."
---

# apsy:llm-pilot — gate G3 (Pilot Verified)

> EXECUTION CONTRACT. Apply the **psynet-engineer** (+ **statistician** for the analysis dry-run) lens.
> **Requires gate G2 = pass.** Produces **SYNTHETIC** data — never reported as human data
> (`config/ethics-policy.md` §2.4–§2.5).

## STEP 1 — Preconditions
Read `.apsy/state.json`: require `gate_statuses.G2 == pass` and `experiment.py` present. Pick a small
pilot **N** (default 5–10) and set the experiment's `test_n_bots = N`.

## STEP 2 — Choose the backend
Read `~/.auto-psynet/config`:
- **External API (OpenAI/OpenRouter)** — the scalable path: `bin/apsy-pilot.sh` drives PsyNet bots whose
  responses come from the configured model (via `apsy_llm_participant.py`).
- **Ambient Claude** (`APSY_LLM_PROVIDER=ambient`, no key) — orchestrator-driven: run a small number of
  bots where **you** (the orchestrator) answer each page as a sampled participant persona. Higher
  fidelity, higher cost on the Claude session, smaller N.
- Optionally sample a **participant population** (a set of personas) for heterogeneity.

## STEP 3 — Run
- External: `bin/apsy-pilot.sh <experiment_dir>` (stages the driver + `conftest.py`, sets
  `APSY_LLM_PILOT=1`, runs `psynet test local`, then `psynet export local`).
- Ambient: drive bots via `BotDriver` answering each page yourself.
- **If psynet is absent**, STOP and point to `/apsy:doctor` — G3 needs the runtime.

## STEP 4 — G3 checks
1. **Pipeline ran end-to-end** — bots completed; no render/async errors.
2. **Doability** — the LLM participants weren't stuck/confused; inspect transcripts
   (`BotResponse.metadata.llm_raw`). A confused LLM is an early signal the task is unclear.
3. **Analysis runs** — dry-run `/apsy:analyze` on the synthetic export; the preregistered analysis
   pipeline must execute (this validates the analysis code before any human data).

## STEP 5 — Verdict + record
- **PASS** — `bin/apsy-state.sh set gate_statuses.G3 pass`; record the silicon-sample summary. Next:
  iterate, or proceed to human deployment (`/apsy:deploy`, gated by **G4**). Write
  `.apsy/reports/G3-pilot.md` **clearly labeling the data synthetic**.
- **FAIL** — return to BUILD/design with the specific problem (a render error, or a task the LLM couldn't
  do). `set gate_statuses.G3 revise`.

**Validation gate:** bots completed; synthetic data exported **and labeled**; the analysis pipeline ran
on it. **Never** present synthetic/LLM results as human evidence.
