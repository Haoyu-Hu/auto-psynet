---
name: recruit
description: "DEPLOY step — configure, launch, and monitor participant recruitment (Prolific/Lucid/MTurk) within the approved spend cap; run live data-quality and decide extend/pause/stop."
---

# apsy:recruit — recruit + monitor

> EXECUTION CONTRACT. Apply the **data-analyst** lens. **Only after gate G4.** Never exceed the approved
> spend cap.

## STEP 1 — Configure the recruiter
Prolific by default (Lucid for global panels, MTurk also supported). Set via `apsy:prolific` /
`apsy:lucid` / `apsy:mturk`: `base_payment`, `wage_per_hour` (**≥ the ethics wage floor, §1.3**),
`prolific_estimated_completion_minutes`, qualifications/screening.

## STEP 2 — Launch
Recruit toward the target N (from §5 / `state.recruitment.target_n`) within `spend.cap_usd`.

## STEP 3 — Monitor (live)
`bin/apsy-recruit.sh status` + incremental `psynet export` → `bin/apsy-data-quality.py <export>
--target-n <N>`: track completion, exclusions, attention/bot screen, and **spend vs cap**. Flag problems
early.

## STEP 4 — Decide extend / pause / stop
- **Stop** when the cap is approached or the (clean) target N is met.
- **Extend** if N is short (re-justify the spend).
- **Pause** on quality problems (low completion, failed attention, bot contamination).

## STEP 5 — Complete
When clean collection meets target, hand off to `/apsy:analyze`.

**Validation gate:** recruitment stays within the approved cap; live data-quality is monitored; the wage
floor is respected. Never let spend exceed `spend.cap_usd`.
