---
command: pilot
description: Run the experiment with LLM-agent participants — validate the pipeline + analysis on synthetic data (gate G3). No human spend.
allowed-tools: Bash, Read, Write, Task, Skill
---

# apsy:pilot — LLM PILOT (gate G3)

Run the **`apsy:llm-pilot`** skill (invoke the Skill tool with skill `apsy:llm-pilot`). **Requires gate
G2 = pass.**

It drives the experiment with LLM participants — the external-API backend via `bin/apsy-pilot.sh`
(OpenAI/OpenRouter, per `apsy:setup`), or the ambient Claude orchestrator — collects **synthetic** data,
and checks gate **G3**: the pipeline runs end-to-end, the preregistered analysis executes on the
synthetic data, and the task is doable.

G3 needs the PsyNet runtime — if absent, run `/apsy:doctor` (install psynet or use the EC2 runtime).
**Synthetic/LLM data is always labeled and never presented as human data** (`config/ethics-policy.md`).
