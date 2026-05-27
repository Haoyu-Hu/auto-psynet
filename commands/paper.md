---
command: paper
description: PUBLISH — assemble the paper draft (Methods from pipeline, Results from analysis) + an OSF-ready reproducibility package.
allowed-tools: Bash, Read, Write, Edit, Task, Skill
---

# apsy:paper — PUBLISH (findings → paper + reproducibility package)

Run the PUBLISH stage (best after gate **G7 = ship**, or to draft from current findings):

1. **`apsy:write-paper`** — assemble the draft from the experiment's artifacts (`.apsy/research-plan.md`,
   `experiment.py`, `.apsy/analysis/results.json` + figures, `.apsy/decisions.md`).
2. **`apsy:repro-package`** — bundle code + locked preregistration + analysis + **anonymized** data.

**Methods** come from the actual pipeline; **Results** come ONLY from the executed analysis
(`.apsy/analysis/results.json`) — never invented. Synthetic / LLM-pilot data is labeled in-silico, and an
**AI-involvement disclosure** is included (`config/ethics-policy.md`).
