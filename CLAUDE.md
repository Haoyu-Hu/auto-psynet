# Auto-PsyNet (`apsy`) — Operating Instructions

> Context for working **inside the `apsy` plugin** and for the plugin's own skills/commands at runtime.
> The full design rationale lives in [`project-plan/`](project-plan/). This file is the constitution.

`apsy` automates the lifecycle of online **behavioral experiments** built on **PsyNet**: a raw idea →
a verified, preregistered research plan → working PsyNet experiment code → LLM-pilot + human deployment
→ analysis & iteration → a publication-ready paper. Subjects can be **humans and/or LLM agents**.

## Core operating principles (non-negotiable)

1. **Ground everything in execution — never fabricate.** The experiment must actually run (`psynet test
   local` green); analyses must actually execute (real stats); numbers come only from executed runs.
   Synthetic / LLM-pilot data is **never** presented as human data.
2. **Conductor / instrument split.** Skills and commands *orchestrate*; the deterministic engine
   (`bin/apsy-*` wrappers around the real `psynet` CLI + analysis runners + the LLM-participant driver)
   *does the work*. Do not hand-simulate PsyNet output.
3. **Preregister, then hold the line.** The analysis plan is locked at gate **G1** and treated as a
   holdout; deviations after data are logged, never silent (defends against p-hacking / HARKing).
4. **File-based state is the source of truth.** Per-experiment state lives in `<experiment>/.apsy/`
   (plan, `state.json`, iteration log, decisions, deployment log) — durable, resumable, compaction-proof.
   Chat memory is never the source of truth.
5. **Human-in-the-loop by default; hard gates never auto-pass.** Autonomy is configurable, but **G4**
   (real human deployment / spend) always requires explicit human approval + an IRB attestation + a
   spend cap — at every autonomy level. See [`config/ethics-policy.md`](config/ethics-policy.md).
6. **Reuse PsyNet's batteries; lead with its differentiators.** Compose PsyNet's consent / demography /
   prescreen modules and paradigms rather than reinventing them. The plugin's value is making PsyNet's
   *hard, novel* paradigms accessible — chains, networks, cross-cultural, human-AI hybrid.

## The pipeline (5 stages, 7 gates)

`FORMULATE →[G1] BUILD →[G2] PILOT&DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH`, with an inner
improvement loop (BUILD ⇄ PILOT ⇄ ANALYZE). Gate rubrics live in `config/gates/`. The workflow-as-code
is `config/pipeline.yaml`. See `project-plan/03-architecture.md`.

## File-creation policy (CRITICAL)

- **Never** write temporary/progress/working files into the plugin directory. Use the session scratchpad
  (`~/.claude/scratchpad/<session-id>/`) for scratch.
- **Per-experiment** artifacts go in that experiment's `<experiment>/.apsy/` directory.
- **User-level** config (LLM backend, username/server prefix, AWS creds, base domain) lives in
  `~/.auto-psynet/config`.
- The plugin directory holds **permanent** files only: `commands/`, `skills/`, `agents/`, `hooks/`,
  `bin/`, `config/`, `tests/`, and docs.

## LLM backend & providers

- The **orchestrator** is always the ambient Claude Code model.
- **LLM participants** (piloting / hybrid) use an **OpenAI or OpenRouter** key (model chosen at
  `apsy:setup`), or fall back to the ambient Claude via subagents. Keeping the *subject* model distinct
  from the *orchestrator* is a feature, not a bug.
- Detection: `OPENAI_API_KEY` / `OPENROUTER_API_KEY`; `AWS` creds for the `ec2` deploy backend.

## Deployment

A pluggable adapter (`bin/apsy-*`): `local` (`psynet debug local`), `llm-pilot` (no web needed), and
**`ec2`** (Dallinger `dallinger ec2 provision`, instances named `{username}.{study}.{host}`, region
`us-east-1` / instance `m7i.{N}xlarge` by default). The `apsy:debug` command selects local vs ec2.

## Name lock

The plugin name `apsy` is locked (see `.claude-plugin/PLUGIN_NAME_LOCK.md`). Repo = `auto-psynet`.

## Status

**Phase 0 (foundations).** Many skills/paradigms are stubs filled per the roadmap
(`project-plan/05-roadmap.md`). Build order: prove the static-trial loop on synthetic data, then the
flagship **GSP** paradigm, then networks / cross-cultural / human-AI hybrid (Track A), with real human
deployment (Track B) gated on infra + approval.
