---
name: deploy
description: "PILOT&DEPLOY gate G4 — deploy the experiment for REAL human data collection. HARD gate: human approval + Cornell IRB attestation + spend cap + G2/G3 green. Never auto-passed at any autonomy level."
---

# apsy:deploy — gate G4 (Deploy Approved) + deploy

> EXECUTION CONTRACT. **THE hard gate for real money / real people.** Never auto-pass at any autonomy
> level (`config/ethics-policy.md` §1.2, §3). Applies the **psynet-engineer** lens + the **human**.

## STEP 1 — Preconditions
Require `gate_statuses.G2 == pass` and `gate_statuses.G3 == pass` (experiment built + piloted). If not,
stop.

## STEP 2 — The G4 gate (all four, in order)
1. **Justification** — present the G3 pilot summary; confirm the design + pilot justify spending.
2. **IRB** — confirm the researcher attests Cornell IRB approval/exemption →
   `bin/apsy-state.sh set irb_attested true`.
3. **Spend cap** — set `spend.cap_usd` (> 0) in `.apsy/state.json`; confirm `wage_per_hour` ≥ the floor
   and `base_payment` (via `apsy:prolific` / `apsy:lucid` / `apsy:mturk`).
4. **Human approval** — get explicit human go-ahead (`AskUserQuestion`). **Only then** export
   `APSY_DEPLOY_APPROVED=1` for this deploy action.

## STEP 3 — Deploy
Choose the backend and run `bin/apsy-deploy.sh <ssh|heroku|ec2>`. Both the `spend-gate` hook and the
script re-verify G4 (defense in depth). The action is recorded to `.apsy/deployment-log.md`.

## STEP 4 — On success
`bin/apsy-state.sh set gate_statuses.G4 pass`. Hand off to `apsy:recruit`.

**PROHIBITED:** setting `APSY_DEPLOY_APPROVED=1` without explicit human approval; deploying without an
IRB attestation or a spend cap; auto-passing G4 in any autonomy mode.
**Validation gate:** never proceed unless all four G4 conditions hold; otherwise block and list what's missing.
