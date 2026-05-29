# Auto-PsyNet — Project Plan

> An autonomous-capable Claude Code plugin that takes a raw behavioral-research idea and carries it
> through a verified research plan → a working PsyNet experiment → LLM-piloted and human deployment →
> data analysis and iteration → a publication-ready scientific paper.

**Plugin call name:** `apsy` (`/apsy:*`) · **Repo:** `auto-psynet` · **Status:** Phases 0-3 + 5
shipped (32 skills · 25 commands · 9 personas · 4 hooks · 1 optional MCP server; assembly green on
`main`). The plugin's full BUILD-to-RUN-to-EXPORT-to-PUBLISH path is end-to-end on a properly
set-up box. The entire runtime-arc is now driven through Claude Code slash commands (with the
`bin/apsy-*` engines still usable standalone in any shell):

```
/apsy:setup → /apsy:install → /apsy:project-dir → /apsy:idea → /apsy:build
            → /apsy:services start → /apsy:debug → /apsy:export → /apsy:debug stop
            → /apsy:services stop → /apsy:analyze → /apsy:paper
```

Each command wraps a deterministic engine (`bin/apsy-services.sh`, `bin/apsy-debug.sh`,
`bin/apsy-export.sh`, etc.) and adds preflight + monitoring + reporting on top. Phase 4 (real
human studies) remains infra-blocked on AWS+domain; everything else is exercised on synthetic data
+ verified via direct psynet 13.2 / dallinger 12.2 runs (2026-05-28).

This directory is the **living plan** for the plugin — the design intent and the rationale, kept in
sync with what's actually shipped. Read the documents in order.

## Documents

| # | Document | What it covers |
|---|----------|----------------|
| 1 | [`01-vision-and-scope.md`](01-vision-and-scope.md) | The problem, the research lifecycle the plugin automates, design principles, the human + LLM-participant model, and what is explicitly in/out of scope. |
| 2 | [`02-reference-synthesis.md`](02-reference-synthesis.md) | What we learned from the four reference repos (PsyNet, Dallinger, octopus, claude-mem) and exactly what we reuse, adapt, or avoid from each. |
| 3 | [`03-architecture.md`](03-architecture.md) | The plugin "harness": components, directory layout, the phased pipeline, quality gates, per-experiment state, the memory layer, the LLM-participant harness, and the deployment adapter. |
| 4 | [`04-skills-agents-commands.md`](04-skills-agents-commands.md) | The **essential skill set**, agent/persona library, slash commands, hooks, the (optional) MCP server, and the **PsyNet Knowledge Pack** (paradigm recipes + domain priors) — each prioritized P0/P1/P2 and mapped to a lifecycle stage. |
| 5 | [`05-roadmap.md`](05-roadmap.md) | Phased build order, the MVP definition, milestones, risks, and open decisions to resolve. |

## Decisions locked at kickoff (2026-05-26)

These four decisions, confirmed with the user, frame the entire plan:

1. **Subjects = humans + LLM agents, with LLM-piloting.** The plugin supports human participants
   *and* LLM-agent participants. Before spending money on humans, it runs the experiment with LLM
   "bots" to validate the pipeline, sanity-check the design, and produce synthetic pilot data.
   Human-vs-LLM comparison studies are a first-class use case. (Enabled by PsyNet's bot system.)
2. **Architecture = standalone, Claude-native, borrowing octopus's patterns.** We build a fresh,
   focused plugin. We reuse octopus's *structural* patterns (skills-as-execution-contracts, a
   persona library, a phased pipeline with quality gates, file-based state, fault-tolerant memory
   bridge) but stay Claude-only and purpose-built — not a fork of octopus.
3. **Autonomy = configurable, supervised by default.** Build the autonomy levels in from the start
   (supervised / semi-autonomous / autonomous), defaulting to supervised. The researcher approves
   phase transitions; automation can be dialed up per project.
4. **Deployment = pluggable adapter; `ec2` (Dallinger) + local.** A `debug` target-selector runs
   experiments **locally or on a Dallinger-provisioned EC2 instance** — the EC2 path resolves the
   HPC-Docker question (D1) and serves both cloud-debug and real deployment; SSH/Heroku remain options.
   Recruitment defaults to **Prolific** (Lucid + MTurk also supported, D4). A first-run **`setup`**
   configures the LLM-participant backend (OpenAI/OpenRouter key, or the ambient Claude model) and the
   `{username}.{study}.{host}` server-naming prefix.
5. **Knowledge = paradigm-primary two-layer pack; the four PsyNet differentiators are headline
   capabilities** (design review, 2026-05-26). A *Paradigm Recipe Library* (by PsyNet `TrialMaker`,
   primary) plus a thin *Domain Design-Priors* layer (by behavioral category), packaged as files the
   skills/personas consult. Chains/iterated paradigms, interacting-participant **networks**,
   **cross-cultural/multilingual**, and **human-AI hybrid** are prioritized early; static trials are the
   stepping stone that proves the loop. Because LLM-piloting develops any paradigm on synthetic data
   with no spend/host, this proceeds in the current environment (Track A) independent of hosting (D1).
   The two layers are cross-linked by a question-archetype **affinity matrix** (a soft prior that also
   flags novel cross-overs) powering proactive paradigm suggestions. First flagship pair = **perception ×
   GSP**; seed domains = perception/psychophysics, music & audio cognition, language, memory-learning-decision.

## The one-paragraph pitch

Behavioral science is bottlenecked on engineering, not ideas: turning a hypothesis into a deployable
experiment, running it correctly, and analyzing it without methodological errors takes weeks of
specialized work. PsyNet already collapses the *deployment* cost of complex online experiments to a
single command. Auto-PsyNet aims to collapse the rest: a Claude Code plugin that pairs a domain-expert
agent team with the real `psynet` toolchain to move from idea to paper, with verification gates (power,
confounds, preregistration, data quality, statistical validity) at every step and an LLM-piloting stage
that de-risks the design before a single human is paid.
