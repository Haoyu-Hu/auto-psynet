---
name: plan-review
description: "FORMULATE gate G1 — score the research plan against the methodological + ethics rubric, surface confounds/validity/ethics issues, and decide pass or revise. Run after the plan is drafted."
---

# apsy:plan-review — gate G1 (Plan Verified)

> EXECUTION CONTRACT. This is the G1 gate. Loads `config/gates/G1.yaml`, `config/blind-spots/*.md`, and
> `config/ethics-policy.md` §1–§2. **A plan with any HARD-level failure does NOT pass.**

## STEP 1 — Load the rubric
Read `config/gates/G1.yaml` (items + levels), the blind-spot checklists, and the ethics policy.

## STEP 2 — Independent review (dispatch personas)
Independence matters at a gate. Dispatch BOTH the **methodologist** and **statistician** as subagents
(Task tool) to review `.apsy/research-plan.md` against the rubric. Each returns
`COMPLETE | BLOCKED | PARTIAL` + per-item findings + blind-spot hits. Do not self-approve without this
independent pass.

## STEP 3 — Score
For each G1 item, mark **pass / advisory / hard-fail**, then run the blind-spot checklist for missed
pitfalls (confounds, demand characteristics, multiplicity, underpowered, p-hacking/HARKing, measurement
invariance, bot contamination, synthetic ≠ human).

## STEP 4 — Verdict + record
- **PASS** — no hard-fail; advisories acknowledged + logged to `.apsy/decisions.md`. The plan is now
  **preregistered**. Run `bin/apsy-state.sh set gate_statuses.G1 pass`, `set stage BUILD`,
  `set next_action "run /apsy:build"`.
- **REVISE** — list the required fixes and loop back to the relevant FORMULATE skill. Run
  `bin/apsy-state.sh set gate_statuses.G1 revise`.

Write the full report to `.apsy/reports/G1-plan-review.md` (create `reports/` if needed).

**Validation gate:** the G1 report exists and `state.json` reflects the verdict. **Never** set G1 `pass`
with an unresolved hard-fail.
