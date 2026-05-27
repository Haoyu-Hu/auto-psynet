---
name: write-paper
description: "PUBLISH step — assemble a publication-ready paper draft: Methods from the actual pipeline + preregistration, Results from the executed analysis (results.json), Intro/Discussion from the literature + findings, with figures and a required AI-involvement disclosure."
---

# apsy:write-paper — assemble the paper

> EXECUTION CONTRACT. Apply the **science-writer** persona. Best run after gate **G6** (verified
> findings). **Every Results number comes ONLY from `.apsy/analysis/results.json` — never invented.**

## STEP 1 — Gather artifacts
`.apsy/research-plan.md` (§1–§8), the real `experiment.py` (what was actually run),
`.apsy/analysis/results.json` + figures, `.apsy/decisions.md` (deviations), and `state.json`
(data provenance: human / synthetic).

## STEP 2 — Draft from the template
Use `config/templates/paper.md.tmpl`:
- **Introduction** — from §8 (literature) + §2 (hypotheses).
- **Methods** — from §4 (design) + `experiment.py` reality (paradigm, conditions, prescreens) +
  participants/N/recruiter/compensation + any **deviations** from `decisions.md`.
- **Results** — effect sizes + 95% CIs from `results.json`, figure references, and the
  decision-rule outcome (H1 supported / refuted / inconclusive).
- **Discussion** — calibrated to the CIs; limitations (incl. power); future work.
- **References** — from §8. **AI-involvement disclosure** — required (ethics §2.7).

## STEP 3 — Honesty checks
No number that isn't in `results.json`; **synthetic / LLM-pilot data labeled in-silico**; deviations
reported; AI-disclosure present.

## STEP 4 — Write
Write `.apsy/reports/paper.md`.

**Validation gate:** every Results figure/number traces to `results.json`; AI-disclosure present;
synthetic data labeled. Hand off to `apsy:repro-package`.
