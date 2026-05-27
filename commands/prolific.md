---
command: prolific
description: Configure Prolific recruitment params (base_payment, wage_per_hour, estimated minutes, qualifications) for the current experiment.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:prolific — Prolific recruiter config

Gather the Prolific params (ask via `AskUserQuestion` where unknown) and record them to the experiment's
`.apsy/state.json` under `recruitment` (they flow into `experiment.py`'s `get_prolific_settings()` at
build): `recruitment.platform = prolific`, `base_payment`, **`wage_per_hour` (≥ the $10 ethics floor,
§1.3)**, `prolific_estimated_completion_minutes`, and a qualifications/screening JSON.

Write each via `bin/apsy-state.sh set recruitment.<key> <value>`. Confirm `wage_per_hour` ≥ the floor.
