---
name: iterate
description: "ANALYZE gate G7 — decide ship or iterate. If iterate, specify the single change + rationale and loop back to BUILD/PILOT, recording the trail. This is the 'improve until satisfied' decision."
---

# apsy:iterate — gate G7 (Iterate or Ship)

> EXECUTION CONTRACT. The improvement-loop decision point.

## STEP 1 — Decide
Given the G6 findings, decide **SHIP** (proceed to PUBLISH) or **ITERATE** (the result, design, or
pipeline needs improvement — e.g. underpowered, a confound surfaced, a pipeline bug, an inconclusive
result worth more data).

## STEP 2 — If ITERATE
Specify the **single change** and its rationale (more power → extend recruitment; confound → redesign;
bug → rebuild). Append it to `.apsy/iteration-log.md`, increment `iteration`, and set `stage` back to
`BUILD` or `PILOT` (`bin/apsy-state.sh set ...`). The relevant earlier gates re-run on the next pass.

## STEP 3 — If SHIP
`bin/apsy-state.sh set gate_statuses.G7 ship`; `set stage PUBLISH`; `set next_action "run /apsy:paper"`.

**Validation gate:** the decision + rationale are recorded in `.apsy/iteration-log.md`, and `state.json`
reflects the next stage.
