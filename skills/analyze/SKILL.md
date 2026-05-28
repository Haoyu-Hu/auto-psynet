---
name: analyze
description: "ANALYZE step — execute the preregistered analysis EXACTLY (the locked §6 model) on the clean data with real stats; compute effect sizes + CIs and figures. Never narrate numbers."
---

# apsy:analyze — run the preregistered analysis

> EXECUTION CONTRACT. Apply the **statistician** lens. **GROUND IN EXECUTION — every number comes from
> the executed run, never from intuition.**

## STEP 1 — Write the analysis script

*(Optional pre-run code-review)* — after writing `.apsy/analysis/analysis.py`, dispatch the
**`code-reviewer`** persona to check the script implements §6 exactly (model, exclusions, primary
outcome) and reports no fabricated numbers, before running it.
From §6 (the LOCKED analysis plan) + `config/templates/analysis.py.tmpl`, write
`.apsy/analysis/analysis.py`: load the trial CSV, apply the preregistered exclusions, fit the **locked
model** (statsmodels / pingouin), and output the effect, 95% CI, p, N, and a primary figure.

## STEP 2 — Run it
`bin/apsy-analyze.sh` (= `python .apsy/analysis/analysis.py <data_dir>`). Read `.apsy/analysis/results.json`.

## STEP 3 — Handle problems honestly
If the locked model cannot run (e.g. non-convergence), **do not silently switch models**. Log the issue
and the minimal, justified fix in `.apsy/decisions.md` as a deviation (G6 checks this).

## STEP 4 — Persist
Save `results.json` + figures under `.apsy/analysis/`. Set `bin/apsy-state.sh set next_action "run apsy:interpret"`.

**Validation gate:** `results.json` exists with an effect + CI from an executed run, and the script
implements the §6 model (not a substitute).
