---
name: power-analysis
description: "FORMULATE step — compute the required sample size for the planned effect and model. Runs real power computation (bin/apsy-power.py); never guesses N."
---

# apsy:power-analysis — required sample size

> EXECUTION CONTRACT. Apply the **statistician** persona. Writes §5. **Ground N in executed computation —
> never assert N from intuition.**

## STEP 1 — Identify the test family + effect size
From §1–§4, pick the analysis family matching the design: `t2` (two-group), `paired`, `corr`, `prop2`
(two proportions), `anova` (k groups). Get the **target effect size** from `apsy:literature-ground` (the
expected effect) or ask the user. If genuinely unknown, plan a **sensitivity analysis** across a
plausible range.

## STEP 2 — Compute
Run `bin/apsy-power.py --test <fam> --effect <es> [--alpha 0.05] [--power 0.8] [--p1 ..] [--groups ..]`.
Use the printed **Required N** + sensitivity table. For nested/mixed designs (trials within participants
within chains) or chain/GSP paradigms where analytic power is intractable, use the closest analytic
family as a floor and **flag that simulation-based power is the proper tool** (a Phase-2 deliverable) —
do not overstate precision.

## STEP 3 — Write §5 + record
Record N (per group / total), the method (`apsy-power.py`, or a sensitivity range), the assumed effect
size + its source, alpha, and target power. Set `bin/apsy-state.sh set recruitment.target_n <N>`.

**Validation gate:** §5 has a concrete N produced by `apsy-power.py` (or a clearly-labeled sensitivity
range) — not a bare assertion.
