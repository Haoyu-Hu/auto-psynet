---
name: psynet
description: "PsyNet function knowledge — paradigm recipes (how to design/build each PsyNet experiment type) + cross-cutting capabilities (synchronization, i18n, prescreening, consent, demography, controls, assets, CLI). Use during design/build of any PsyNet experiment; open the matching psynet-function/ subfile."
---

# apsy:psynet — PsyNet function knowledge pack

This skill is the **index** to Auto-PsyNet's PsyNet-specific knowledge. Every function-specific reference
lives under **`psynet-function/`**. The `design` skill selects a paradigm via `config/affinity.yaml`
(question-archetype → paradigm), then `implement-paradigm` opens the matching recipe here to generate
code. The `psynet-engineer` persona owns this knowledge.

## How to use
1. From the locked plan, identify the **paradigm** (or the cross-cutting need).
2. Open `psynet-function/<name>.md` — each recipe gives *when to use it · the `Trial`/`Node`/`TrialMaker`
   classes + overrides · `bot_response` · gotchas · a worked-example pointer · the export data shape*.
3. Generate code against the recipe; the bar is a green `psynet test local` (gate G2).
   Always honor the 8 global gotchas (see `agents/psynet-engineer.md`).

## Paradigm recipes (`psynet-function/`) — filename = `config/affinity.yaml` paradigm id

| Subfile | TrialMaker | Responsible for |
|---------|-----------|-----------------|
| [`static.md`](psynet-function/static.md) | `StaticTrialMaker` | Fixed stimulus set: rating/judgment/classification (MVP base). |
| [`gsp.md`](psynet-function/gsp.md) | `GibbsTrialMaker` (+ media/audio) | Gibbs Sampling with People — recover mental representations/priors. **★ flagship.** |
| [`mcmcp.md`](psynet-function/mcmcp.md) | `MCMCPTrialMaker` | MCMC with People — sample mental categories via 2AFC. |
| [`imitation_chain.md`](psynet-function/imitation_chain.md) | `ImitationChainTrialMaker` | Transmission chains / iterated learning (cultural evolution, memory). |
| [`graph_chain.md`](psynet-function/graph_chain.md) | `GraphChainTrialMaker` (+ `SyncGroups`) | Networks / interacting participants / real-time multiplayer. |
| [`staircase.md`](psynet-function/staircase.md) | `GeometricStaircaseTrialMaker` | Adaptive psychophysics — detection/discrimination thresholds. |
| [`dense.md`](psynet-function/dense.md) | `DenseTrialMaker` | Dense sampling of a continuous space (AXB, same-different, slider-copy). |
| [`create_and_rate.md`](psynet-function/create_and_rate.md) | `CreateAndRate` mixin | Generate-and-evaluate (creativity, aesthetics, stimulus selection). |

## Cross-cutting PsyNet functions (`psynet-function/`)

| Subfile | Responsible for |
|---------|-----------------|
| [`synchronization.md`](psynet-function/synchronization.md) | Real-time multiplayer (`SyncGroups`, `sync_group_type`), wait pages — and human-AI hybrid. |
| [`internationalization.md`](psynet-function/internationalization.md) | i18n (`psynet translate`, `get_translator`), locales — cross-cultural studies + measurement invariance. |
| [`prescreening.md`](psynet-function/prescreening.md) | Drop-in prescreens: attention, headphone, color-blindness, LexTale, vocab. |
| [`consent.md`](psynet-function/consent.md) | Consent modules (`MainConsent` + custom `(Module, Consent)` pattern); placed first. |
| [`demography.md`](psynet-function/demography.md) | Demography modules + standardized instruments (GMSI, PEI). |
| [`timeline-and-controls.md`](psynet-function/timeline-and-controls.md) | Timeline, `ModularPage` (Prompt+Control catalog), `PageMaker`, `CodeBlock`, control flow. |
| [`assets-and-stimuli.md`](psynet-function/assets-and-stimuli.md) | The `Asset` system, media storage, `compile_nodes_from_directory`, `synth_function`. |
| [`cli-and-deployment.md`](psynet-function/cli-and-deployment.md) | The `psynet` CLI (debug/deploy/export/test/update-scripts) + recruiters. |

> Domain priors (perception, etc.) are separate (`config/domains/`). The selector matrix is
> `config/affinity.yaml`. This is a knowledge pack consulted by skills — not a set of auto-firing skills.
