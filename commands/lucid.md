---
command: lucid
description: Configure Lucid/Cint recruitment params (global panels) for the current experiment.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:lucid — Lucid recruiter config

Configure Lucid/Cint recruitment (global/representative panels — useful for cross-cultural studies).
Record to `.apsy/state.json` under `recruitment`: `recruitment.platform = lucid`, plus the Lucid
parameters (locale/target group, completion estimate, payment) and the wage settings (**≥ the $10 ethics
floor, §1.3**). Write via `bin/apsy-state.sh set recruitment.<key> <value>`. See PsyNet's `psynet lucid`
tooling for cost/locale management.
