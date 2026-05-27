---
name: literature-ground
description: "FORMULATE step — situate the idea in the literature: prior paradigms, expected effect sizes, and the novelty gap. Uses web search + arXiv, plus the Semantic Scholar API when SEMANTIC_SCHOLAR_API_KEY is set."
---

# apsy:literature-ground — situate the idea

> EXECUTION CONTRACT. Produces §8 of `.apsy/research-plan.md`. **Cite real sources; never fabricate
> citations.** (The dedicated `literature-scholar` persona arrives in Phase 3; until then apply the
> methodologist lens.)

## STEP 1 — Build queries
From §1–§3 (question + constructs), derive 3–6 queries spanning the construct, the paradigm family, and
likely effect-size sources.

## STEP 2 — Search
- `WebSearch` for recent reviews + key empirical papers.
- arXiv (e.g. q-bio.NC, cs.HC) via `WebSearch`/`WebFetch`.
- **If `SEMANTIC_SCHOLAR_API_KEY` is set**, query the Semantic Scholar API for citations + abstracts.
Defaults are web search + arXiv; Semantic Scholar is additive (decision D6).

## STEP 3 — Synthesize
Summarize prior paradigms for this question, **typical / expected effect sizes** (these feed
`apsy:power-analysis`), and the **novelty gap** this study fills. Note pitfalls prior work hit
(cross-reference `config/blind-spots/`).

## STEP 4 — Write §8
Write §8 (Background & references) with real citations — or an explicit "no strong priors found → use a
sensitivity analysis for power."

**Validation gate:** §8 has real citations or the explicit no-priors note; an expected effect size (or a
justified range) is recorded for the power step.
