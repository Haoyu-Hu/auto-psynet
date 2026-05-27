# PsyNet function: Demography

**What:** standardized demographic questionnaires + validated instruments, composed into the timeline.

**Modules (`psynet/demography`):** `BasicDemography`, `Age`, `Gender`, `CountryOfBirth`,
`FormalEducation`, `MotherTongue`, `ExperimentFeedback`. Standardized instruments: **`GMSI`** (Goldsmiths
Musical Sophistication Index) and **`PEI`**.

**Use:** place after prescreens; compose only the modules the analysis needs; each exports its own data.

**Gotchas:** collect only what's needed (PII minimization, ethics §1.6); each module adds a
`time_estimate`; for cross-cultural runs, wrap any custom items with the translator (see
`internationalization.md`).
