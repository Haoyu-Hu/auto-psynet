---
command: idea
description: Start FORMULATE — turn a research idea into a verified, preregistered research plan (gate G1).
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Task, WebSearch, WebFetch, Skill
---

# apsy:idea — FORMULATE (idea → verified, preregistered plan)

Orchestrate the FORMULATE stage for the idea in `$ARGUMENTS` (ask for it if empty). Run the skills in
order — each writes its section of `.apsy/research-plan.md` — and honor the autonomy level in
`.apsy/state.json` (default **supervised** = pause for the user at the G1 gate).

1. **`apsy:formulate`** — scaffold `.apsy/`, capture the idea, write §1–§3 (question, hypotheses,
   variables; name the archetype + domain).
2. **`apsy:literature-ground`** — situate in the literature; write §8; record an expected effect size.
   (Skip only if the user opts out.)
3. **`apsy:design`** — select the paradigm via `config/affinity.yaml` (offer a differentiating-paradigm
   upgrade when defensible); write §4.
4. **`apsy:power-analysis`** — compute N with `bin/apsy-power.py`; write §5.
5. **`apsy:analysis-plan`** — lock the preregistered analysis; write §6 (🔒).
6. **`apsy:plan-review`** — run gate **G1** (independent methodologist + statistician review). In
   supervised mode, present the verdict and **require explicit user approval** before marking the plan
   preregistered.

On **G1 PASS** the plan is preregistered and `state.json` advances to `stage: BUILD` (next: `/apsy:build`).
On **REVISE**, loop back to the flagged step. **Never fabricate findings or claim G1 passed with an
unresolved hard-fail** (`config/ethics-policy.md`).
