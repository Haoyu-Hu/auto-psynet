---
name: analysis-plan
description: "FORMULATE step — lock the preregistered analysis plan (statistical model, primary/secondary outcomes, decision rules) BEFORE data. This is the holdout that defends against p-hacking."
---

# apsy:analysis-plan — lock the preregistered analysis

> EXECUTION CONTRACT. Apply the **statistician** persona. Writes §6 and marks it 🔒 LOCKED. After this the
> analysis cannot be silently changed — G6 verifies it matched, and any deviation is logged in
> `.apsy/decisions.md`.

## STEP 1 — Choose the model (match the design's nesting)
Specify the **primary statistical model** matching the design: e.g. a mixed-effects logistic model for
nested accuracy (trials within participants), a linear mixed model for continuous DVs, or the
paradigm-appropriate analysis for GSP/chains (e.g. stationary-distribution / chain-level analysis). The
model must respect non-independence.

## STEP 2 — Specify outcomes + rules
- **Primary outcome** and the exact test of H1.
- **Secondary** outcomes (labeled exploratory if not pre-specified — no HARKing).
- Covariates, **multiple-comparison** handling, and **exclusion rules** (link to G5).
- Explicit **decision rules**: what result supports vs. refutes H1.

## STEP 3 — Lock it
Write §6 (Analysis plan) and mark it 🔒 LOCKED. Set `bin/apsy-state.sh set analysis_locked true`.

**Validation gate:** §6 present and locked; the model matches the design's nesting; primary outcome +
decision rule are unambiguous.
