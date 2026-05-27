# 01 — Vision & Scope

## 1.1 The problem

Designing and running a rigorous online behavioral experiment is a long, error-prone, specialist
pipeline. A researcher must: formalize a vague idea into testable hypotheses; operationalize
constructs into concrete stimuli and measures; choose an appropriate paradigm; control confounds and
counterbalance; compute the sample size needed for adequate power; implement the experiment as working
software; recruit and pay participants; clean and analyze the data without falling into statistical
traps; and write it up. Each step has well-known failure modes (underpowered designs, confounded
manipulations, demand characteristics, p-hacking, HARKing, bot/bad-actor contamination), and most of
the elapsed time is *engineering and logistics*, not science.

[PsyNet](../materials/psynet) already removes a huge part of this cost: it turns a complex experiment
into a single declarative Python `Experiment` class and deploys it — server provisioning, recruitment,
payment, monitoring — with one command. But authoring the experiment correctly, designing it
rigorously, and analyzing it soundly still require a skilled research engineer.

**Auto-PsyNet's thesis:** an agent that (a) knows experimental methodology and statistics, (b) knows
PsyNet deeply, and (c) drives the *real* `psynet` toolchain and *real* analysis code — gated by
verification at every step — can take a researcher from idea to paper far faster, while *raising* the
methodological floor rather than lowering it.

## 1.2 The research lifecycle we automate

The user's five steps map to a five-stage pipeline with an inner improvement loop. We give the stages
verb names and define a **verification gate** between each (gates detailed in
[`03-architecture.md`](03-architecture.md)).

```
  ┌─────────────┐   G1    ┌─────────┐   G2   ┌──────────────────┐   G3/G4   ┌───────────┐   G5/G6   ┌──────────┐
  │ 1 FORMULATE │────────▶│ 2 BUILD │───────▶│ 3 PILOT & DEPLOY │──────────▶│ 4 ANALYZE │──────────▶│ 5 PUBLISH│
  │ idea→plan   │  plan   │ PsyNet  │ build  │ LLM pilot → human│  data     │ data→     │ findings  │ paper +  │
  │             │ verified│ code    │verified│ recruitment      │ collected │ findings  │ verified  │ repro pkg│
  └─────────────┘         └─────────┘        └──────────────────┘           └───────────┘           └──────────┘
                               ▲                      │                            │
                               │                      ▼                            │
                               └──────────── iterate (steps 2–4) ◀─────────────────┘
                                          "improve until satisfied"
```

### Stage 1 — FORMULATE (raw idea → *verified* research plan)
Turn a one-line idea into a structured, defensible research plan:
- Research question and **hypotheses** (directional, falsifiable).
- **Operationalization**: independent/dependent variables, constructs → concrete measures and stimuli.
- **Literature grounding**: situate against prior work; establish novelty and the expected effect.
- **Design**: paradigm selection (mapped to a PsyNet `TrialMaker`), conditions, within/between, counterbalancing, randomization, prescreening/exclusion criteria.
- **Power analysis**: required N (analytic or simulation-based) for the target effect.
- **Analysis plan**: the statistical model and decision rules, *locked before data* (preregistration).
- **Ethics**: consent, risk, compensation fairness, data privacy.

"**Verified**" means the plan passes a scored methodological review (the G1 gate): construct validity,
internal validity, statistical-conclusion validity, novelty, feasibility, and ethics. This is the
single highest-leverage stage — most experiments fail here, silently, and only reveal it after data.

### Stage 2 — BUILD (verified plan → working PsyNet experiment)
Generate a real PsyNet project from the plan: the `Experiment` class, the paradigm-specific
`Trial`/`Node`/`TrialMaker` subclasses, the timeline (consent → instructions → prescreens → demography
→ trial makers → feedback → debrief), stimuli, and `config.txt`. Then make it *self-verifying* with
bot tests until `psynet test local` is green. The output is runnable software, not a sketch.

### Stage 3 — PILOT & DEPLOY (working experiment → collected data)
Two sub-phases, deliberately ordered to de-risk spend:
- **3a LLM pilot:** run the experiment end-to-end with **LLM-agent participants** (§1.4). Validates
  that every page renders and every control works, sanity-checks whether the task is even doable,
  exercises the analysis pipeline on synthetic data, and yields a "silicon-sample" baseline. No human
  money spent. This is the gate (G3) before any human deployment.
- **3b Human deployment:** deploy via the chosen adapter and recruit (Prolific/MTurk). Guarded by an
  explicit human approval + hard spend cap (G4) because this is the first irreversible, real-money,
  real-people step. Monitor data quality live.

### Stage 4 — ANALYZE (collected data → *verified* findings)
Export data, run **data-quality** screening (attention checks, completion, exclusions, bot detection),
execute the **preregistered analysis** exactly as locked in Stage 1, report effect sizes and
uncertainty, and document any deviations. The G6 gate checks that the analysis matched the plan and the
result is robust. Then decide: **ship or iterate** (G7). Iteration loops back to Stage 2/3 with a
recorded rationale for what changes and why.

### Stage 5 — PUBLISH (verified findings → paper + reproducibility package)
Assemble the scientific paper — Methods auto-derived from the actual pipeline, Results from the actual
analysis, Introduction/Discussion grounded in the literature and the findings — plus figures, and a
reproducibility package (code + data + analysis + preregistration, OSF-style). The "research skeleton"
the user asked for is this structured, regenerable artifact.

## 1.3 Design principles

These are distilled from the reference systems (see [`02-reference-synthesis.md`](02-reference-synthesis.md))
and from scientific-integrity requirements.

1. **Ground everything in execution — no vibes.** The experiment must actually run (`psynet test
   local` green); the analysis must actually execute (real stats packages); results must be computed,
   never narrated. The agent *drives* the real toolchain; it never hand-simulates PsyNet output or
   invents numbers.
2. **Conductor / instrument split.** Skills and commands *orchestrate*; a deterministic engine (thin
   wrappers around the `psynet` CLI, analysis scripts, and APIs) *does the work*. This keeps behavior
   reproducible and testable, exactly as octopus separates its skills from `orchestrate.sh`.
3. **Verification gates between every stage.** Each transition has a checklist/scored gate. Gates are
   where methodology is enforced and where the configurable autonomy level decides whether to pause
   for human approval.
4. **Preregister, then hold the line.** The analysis plan is locked at G1 and treated like a holdout
   set (octopus's "Dark Factory" holdout pattern, applied to science): the analysis cannot be silently
   changed after seeing data. Deviations are allowed but must be explicit and logged. This is the
   structural defense against p-hacking and HARKing.
5. **File-based, per-experiment state is the source of truth.** Because data collection spans days,
   the plan, iteration log, and deployment/spend log live as files committed into each experiment repo
   — durable, auditable, resumable, and compaction-resistant. Chat memory is never the source of truth.
6. **Encode methodological pitfalls as a blind-spot library.** Like octopus's blind-spot checklists,
   maintain keyword-triggered, injectable lists of "things behavioral experiments systematically get
   wrong" (confounds, order effects, multiple comparisons, ceiling/floor, etc.) that gates consult.
7. **Human-in-the-loop by default; autonomy is opt-in and capped.** Anything irreversible or
   real-money/real-people requires explicit approval at the default autonomy level. Cost caps are hard
   gates, not suggestions.
8. **Reuse PsyNet's batteries.** PsyNet ships consent modules, demography instruments, prescreening
   tasks, and a dozen paradigms. The plugin composes these rather than reinventing them.
9. **Lead with PsyNet's differentiators.** The plugin's value is not automating vanilla questionnaires —
   it is making PsyNet's *hard, novel* paradigms accessible: transmission chains and cultural-evolution
   sampling (chains/GSP/MCMCP), interacting-participant **networks** (graph chains + real-time sync),
   **cross-cultural/multilingual** studies (i18n + global panels), and **human-AI hybrid** designs. The
   FORMULATE stage proactively proposes elevating an idea to one of these when it would make the
   research more powerful or novel (see [`04-skills-agents-commands.md`](04-skills-agents-commands.md) §4.0).

## 1.4 The human + LLM-participant model

This is a flagship capability and a direct consequence of the kickoff decision. PsyNet already runs
automated participants ("bots") for testing: every response `Control` accepts a `bot_response` value or
lambda, and a `BotDriver` walks a bot through the timeline over HTTP exactly like a human. We exploit
this on three levels:

- **Level 0 — Test bots (deterministic).** What PsyNet does today: fixed/random `bot_response` to make
  the experiment self-testing. Used in Stage 2 to prove the pipeline runs.
- **Level 1 — LLM participants (piloting).** Replace `bot_response` with an **LLM call**: render each
  page's prompt and the affordances of its control into text, ask a Claude model (given a participant
  persona and the task instructions) to respond, and parse the answer back into the control's expected
  format. This produces realistic synthetic data for piloting and analysis-pipeline shakedown — Stage
  3a. No human spend.
- **Level 2 — LLM subjects (research).** The same harness, treated as the actual sample for in-silico
  studies or as the model arm of a **human-vs-LLM comparison** ("do LLMs show effect X that humans
  show?"). This is a real and active research area; the plugin enables it but is explicit about its
  scientific caveats (see scope below).
- **Level 3 — Human-AI hybrid / collaborative.** The harness combined with PsyNet's real-time
  synchronization (`SyncGroups`, `sync_group_type`) lets **humans and LLM agents participate in the same
  chain or network**: alternating human↔AI transmission chains, mixed human-AI networks, or
  collaborative human-AI tasks. This is the most novel capability the plugin unlocks and is treated as a
  headline differentiator (see §1.5 and the roadmap). It requires mixed-sample analysis methods
  (non-independence, exchangeability).

The LLM-participant harness is described concretely in [`03-architecture.md`](03-architecture.md §3.6).

## 1.5 Scope

### In scope (what the plugin is)
- A Claude Code plugin (skills + agents + commands + hooks + optional MCP) for the full
  idea→paper lifecycle of **online behavioral experiments built on PsyNet**.
- Support for both **human** and **LLM-agent** participants, with LLM-piloting as a standard de-risking
  step.
- **First-class support for PsyNet's differentiating capabilities** as headline features: chain/iterated
  paradigms, interacting-participant **networks** (incl. real-time sync), **cross-cultural/multilingual**
  deployment, and **human-AI hybrid/collaborative** designs.
- **Configurable autonomy**, supervised by default.
- A **pluggable deployment** abstraction (local/LLM-pilot now; SSH/Heroku later).
- Cross-experiment **memory** so methodology and lessons accumulate across studies.

### Out of scope (at least initially)
- Experiment frameworks other than PsyNet/Dallinger. (The architecture isolates PsyNet behind an
  engine layer, so this is a future possibility, not a current goal.)
- Lab/in-person studies, fMRI/EEG, or anything PsyNet/Dallinger doesn't target.
- Being a general-purpose multi-LLM orchestrator (that is octopus's job; we borrow patterns, not scope).
- Replacing the researcher's judgment or IRB. The plugin **proposes and verifies**; a human owns
  ethical and scientific accountability.

### Hard guardrails (non-negotiable)
- **No real human recruitment or payment without explicit human approval** and a configured spend cap,
  regardless of autonomy level.
- **No fabricated data or results.** Numbers come only from executed analyses on real or clearly-labeled
  synthetic (LLM-pilot) data; synthetic data is never presented as human data.
- **No silent analysis changes** after data collection; the preregistered plan governs, deviations are
  logged.
- **Scientific-validity honesty for LLM subjects.** When LLMs are used as subjects, outputs are labeled
  as in-silico and the known validity caveats are stated; LLM pilot results are never passed off as
  evidence about humans.

## 1.6 What "done" looks like (north star)

A researcher types `/apsy:idea "Does background music tempo affect risk-taking in a balloon-pump task?"`,
and — with approvals at each gate — ends up with: a preregistered plan with a power-justified N; a
working PsyNet experiment that passes its bot tests; an LLM-pilot run showing the pipeline and analysis
work end-to-end; a deployed Prolific study within an approved budget; a clean analysis with effect
sizes and figures; and a drafted paper plus an OSF-ready reproducibility package — with every decision,
deviation, and dollar logged in the experiment's own repo.
