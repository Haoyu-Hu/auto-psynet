---
name: export-data
description: "ANALYZE step — export the experiment's data (psynet export) or load a prior/pilot export, and locate the per-class CSVs for analysis. Also consumes LLM-pilot synthetic data."
---

# apsy:export-data — get the data

> EXECUTION CONTRACT. Apply the **data-analyst** lens. **Always record whether the data is HUMAN or
> SYNTHETIC (LLM-pilot) — never conflate the two** (`config/ethics-policy.md` §2.4).

## STEP 1 — Source the data
- Real run → `bin/apsy-export.sh <experiment_dir>` (`psynet export local`).
- Pilot → the synthetic export already produced by `bin/apsy-pilot.sh`.
- Prior archive → re-ingest `database.zip`.
If psynet is absent and there is no existing export, stop and point to `/apsy:doctor`.

## STEP 2 — Locate the CSVs
Find `data/*.csv` (one CSV per most-specific class, e.g. `MyTrial.csv` carrying `definition`, `answer`,
`score`, `participant_id`, `trial_maker_id`, `failed`). Confirm the trial CSV(s) + the participant CSV.

## STEP 3 — Record provenance
Note the export path and the **provenance (human / synthetic)** in `.apsy/state.json`
(`bin/apsy-state.sh set ...`) and the report.

**Validation gate:** the trial + participant CSVs are found and provenance is recorded.
