---
command: analyze
description: Export data and run the preregistered analysis; report effects, then iterate or ship (gates G5/G6/G7).
allowed-tools: Bash, Read, Write, Edit, Task, Skill
---

# apsy:analyze — ANALYZE (data → verified findings)

Orchestrate the ANALYZE stage. Run the skills in order, honoring the autonomy level in `.apsy/state.json`:

1. **`apsy:export-data`** — export (`psynet export`) or load the pilot/prior data; record provenance
   (human / synthetic).
2. **`apsy:data-quality`** — gate **G5**: completion, the preregistered exclusions, duplicates, target-N
   → the clean dataset.
3. **`apsy:analyze`** — write + run the **LOCKED §6** analysis (real stats); effects + CIs + figures.
4. **`apsy:interpret`** — gate **G6**: verify analysis-matched-prereg; report effect + CI; is H1 supported?
5. **`apsy:iterate`** — gate **G7**: **ship** → `/apsy:paper`, or **iterate** → loop to BUILD/PILOT.

Numbers come **only** from executed analyses; deviations from the locked plan are logged, never silent.
Synthetic / LLM-pilot results are labeled in-silico and never presented as human data
(`config/ethics-policy.md`).
