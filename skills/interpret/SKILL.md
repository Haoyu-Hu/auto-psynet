---
name: interpret
description: "ANALYZE gate G6 — map the executed results to the hypotheses: effect sizes, uncertainty, robustness, and whether H1 is supported per the preregistered decision rules. Verifies the analysis matched the plan."
---

# apsy:interpret — gate G6 (Findings Verified)

> EXECUTION CONTRACT. Apply the **statistician** lens.

## STEP 1 — Verify analysis-matched-prereg
Confirm the executed analysis matched §6 (same model, outcomes, exclusions). List any deviations — each
must already be logged in `.apsy/decisions.md`. **An unlogged deviation fails G6.**

## STEP 2 — Apply the decision rules
Using the preregistered decision rules, state whether H1 is **supported / refuted / inconclusive**.
Report the **effect size + 95% CI + uncertainty** — not just a p-value.

## STEP 3 — Robustness + provenance
Run any preregistered robustness/sensitivity checks. **If the data is synthetic / LLM-pilot, label the
findings as in-silico — never as human evidence** (`config/ethics-policy.md` §2.5).

**Optional red-team pass:** dispatch the **`adversarial-reviewer`** to red-team the findings —
analysis-matched-prereg? alternative explanations? CIs honest about the claims? synthetic-vs-human
conflation? AI-disclosure present? Its severity-tiered findings inform the G6 verdict.

## STEP 4 — Verdict
- **PASS** — analysis matched the prereg; result is interpretable. `bin/apsy-state.sh set
  gate_statuses.G6 pass`; write `.apsy/reports/G6-findings.md` (effect, CI, verdict, provenance).
- **REVISE** — re-analyze or document.

**Validation gate:** analysis-matched-prereg confirmed (or deviations logged); effect + CI reported;
synthetic data labeled. Hand off to `apsy:iterate`.
