---
command: mturk
description: Configure Amazon Mechanical Turk recruitment params for the current experiment.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:mturk — MTurk recruiter config

Configure Amazon Mechanical Turk recruitment. Record to `.apsy/state.json` under `recruitment`:
`recruitment.platform = mturk`, `base_payment`, **`wage_per_hour` (≥ the $10 ethics floor, §1.3)**,
qualification requirements, and HIT settings. Write via `bin/apsy-state.sh set recruitment.<key> <value>`.
