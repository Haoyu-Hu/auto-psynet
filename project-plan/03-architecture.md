# 03 — Architecture (the harness)

This document defines the plugin's components, how they fit together, and the infrastructure they
depend on. It answers the kickoff question: *what is necessary, and which harness is essential.*

## 3.1 Component overview

Auto-PsyNet is a Claude Code plugin (the "brain": skills/agents/commands/hooks) driving a deterministic
engine (the "hands": wrappers around the real `psynet` CLI, analysis runners, and external APIs), with
a file-based state/memory layer (the "notebook") and a pluggable runtime (the "lab").

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  CLAUDE CODE PLUGIN  (the brain — declarative)                                     │
│                                                                                    │
│  Commands (25) — Bootstrap · Discover · Pipeline · Meta · Per-experiment config.   │
│                  Canonical list in doc 04 §4.3; live in-CLI via /apsy:help.        │
│      │                                                                             │
│      ▼                                                                             │
│  Skills (EXECUTION CONTRACTS) ── orchestrate ──▶ Agents / Personas (expert brains) │
│   formulate·design·power·plan-review │ scaffold·implement·test │ llm-pilot·deploy  │
│   ·recruit │ data-quality·analyze·interpret │ write-paper·repro-package            │
│      │                                                                             │
│  Hooks: SessionStart(load-experiment-context, first-run-nudge) · PreToolUse(       │
│         psynet-lint on experiment.py, spend-gate G4 on Bash) [+ PostToolUse]       │
└──────────────────────────────────────────────────────────────────────────────────┘
        │ shells out to                                  │ reads/writes
        ▼                                                ▼
┌─────────────────────────────────────────┐   ┌────────────────────────────────────┐
│  ENGINE  (the hands — deterministic)     │   │  STATE & MEMORY  (the notebook)     │
│  bin/apsy-* wrappers:                      │   │  per-experiment  <exp>/.apsy/        │
│   • psynet CLI (debug/deploy/export/test) │   │    research-plan.md (preregistration)│
│   • analysis runner (Python/R)            │   │    state.json · iteration-log.md    │
│   • power/stats helpers                    │   │    decisions.md · deployment-log.md │
│   • LLM-participant driver                 │   │    analysis/ · reports/             │
│   • literature / Prolific / OSF clients    │   │  user-level  ~/.auto-psynet/        │
│   • deployment adapter (local/ssh/heroku)  │   │  memory: files + native (no ext)    │
└─────────────────────────────────────────┘   └────────────────────────────────────┘
        │ provisions / runs
        ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│  RUNTIME  (the lab — pluggable)   Docker · Postgres · Redis · psynet worker/clock  │
│  local debug  │  LLM-pilot (no web needed)  │  [later] SSH host  │  [later] Heroku  │
│  recruiters: generic/hotair (dev) │ Prolific / MTurk (real)                         │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## 3.2 Proposed plugin directory layout

Mirrors octopus's proven layout, scaled down and renamed. `${CLAUDE_PLUGIN_ROOT}` is the repo root.

```
auto-psynet/                          # the plugin repo (this repo)
├── .claude-plugin/
│   ├── plugin.json                   # name:"apsy" (LOCKED), version, explicit skills[] + commands[]
│   ├── marketplace.json              # marketplace entry (name must match plugin.json)
│   └── PLUGIN_NAME_LOCK.md           # why the name stays "apsy"
├── commands/                         # slash command .md files (see doc 04) — 25 commands
├── skills/                           # SKILL.md execution contracts (one dir each, see doc 04) — 32 skills
│   ├── setup/ install/ update/ doctor/ status/
│   ├── formulate/ design/ power-analysis/ analysis-plan/ plan-review/
│   ├── scaffold/ implement-paradigm/ wire-timeline/ test-experiment/
│   ├── llm-pilot/ debug/ deploy/ recruit/
│   ├── data-quality/ analyze/ interpret/ iterate/ export-data/
│   ├── write-paper/ repro-package/
│   ├── auto/ run/ add-recipe/
│   └── psynet/                       # PsyNet knowledge hub: SKILL.md index + psynet-function/ (8 paradigm + 8 cross-cutting recipes)
├── agents/                           # persona library + routing registry (flat)
│   ├── *.md                          # personas (methodologist, statistician, psynet-engineer, …) — 9 personas
│   └── config.yaml                   # routing: persona → stage → model → tools
├── hooks/                            # lifecycle hooks — scripts + their JSON wiring (NOT in .claude-plugin/)
│   ├── hooks.json                    # SessionStart / PreToolUse wiring (lives here, not .claude-plugin/)
│   ├── load-experiment-context.sh    # SessionStart: inject .apsy/state.json if in an experiment dir
│   ├── first-run-nudge.sh            # SessionStart: nudge /apsy:setup when ~/.auto-psynet/config absent
│   ├── psynet-lint.sh                # PreToolUse Edit|Write: inject PsyNet code-gen gotchas
│   └── spend-gate.sh                 # PreToolUse Bash: HARD G4 block on real deploy/recruit
├── bin/                              # the deterministic engine (apsy-*.{sh,py} wrappers) — 23 helpers
│   ├── apsy-common.sh                #   shared: config I/O + apsy_resolve_python (interpreter resolver)
│   ├── apsy-config.sh                #   user-level config get/set (~/.auto-psynet/config)
│   ├── apsy-install.sh apsy-update*  #   pip install/upgrade + managed venv (--create-venv)
│   ├── apsy-check.sh                 #   focused dep + version check (deps, PyPI latest, drift)
│   ├── apsy-doctor.sh apsy-state.sh  #   diagnostics + per-experiment state
│   ├── apsy-services.sh              #   start/stop/status of Redis + Postgres for `psynet debug
│   │                                 #   local`; auto-detects binaries (PATH or conda); initdb's
│   │                                 #   pg + creates dallinger user + db; idempotent
│   ├── apsy-debug.sh                 #   pre-launch auto-fix (.gitignore/git init/constraints.txt) +
│   │                                 #   Redis+Postgres reachability checks + lifecycle reminder →
│   │                                 #   nohup-launch + PID-file write + `stop` subcommand
│   ├── apsy-export.sh                #   wrapper for `psynet export local`; auto-adds
│   │                                 #   `--path $APSY_PROJECT_DIR/data/<study>` for redirect
│   ├── apsy-link-data.sh             #   5-case safety symlink helper for `~/psynet-data` →
│   │                                 #   $APSY_PROJECT_DIR/data (refuses if target has content)
│   ├── apsy-deploy.sh                #   deploy adapter (local/llm-pilot/ec2) — G4-gated
│   ├── apsy-recruit.sh               #   recruitment status (Prolific/Lucid/MTurk thin)
│   ├── apsy-route.py apsy-run.py     #   smart router + autonomous pipeline state machine
│   ├── apsy-power.py apsy-data-quality.py   #   stats helpers (effect sizes, exclusions)
│   ├── apsy-repro.sh                 #   OSF-ready repro package assembler (code + paper + gates)
│   ├── apsy-pilot.sh apsy_llm_participant.py   #   LLM-participant pilot driver + bot monkeypatch
│   └── apsy-add-recipe.py            #   extend the PsyNet knowledge pack (auto-index parent SKILL.md)
├── config/
│   ├── pipeline.yaml                 # the 5-stage workflow-as-code (agents, gates, thresholds)
│   ├── ethics-policy.md              # G4 guardrails, IRB attestation, spend caps
│   ├── gates/                        # gate rubrics (G1..G7) as scored checklists
│   ├── affinity.yaml                 # question-archetype × paradigm selector matrix
│   ├── domains/                      # Domain Design-Priors (paradigm recipes are in skills/psynet/psynet-function/)
│   ├── blind-spots/                  # methodological/statistical pitfall library (incl. measurement invariance)
│   └── templates/                    # .apsy/ state-file templates + experiment scaffolds + paper.md.tmpl
├── mcp-server/                       # OPTIONAL, opt-in (off by default): stdlib MCP server (6 tools, thin engine wrappers)
├── tests/                            # plugin self-tests (validate-assembly.sh)
├── project-plan/                     # this directory: the living design
├── CLAUDE.md                         # plugin operating instructions (policies, file rules)
└── README.md
```

> **Dev-only references (gitignored, NOT shipped):** `materials/` (PsyNet + Dallinger clones for grep/reference)
> and `experiment-examples/` (real Cornell Jacoby-lab studies). They power authoring but never appear in the
> released plugin; recipe references resolve against the **installed** psynet package via `APSY_PSYNET_PATH`.

**Manifest rules:** `plugin.json.name = "apsy"` is locked and equals the `/apsy:*` namespace; npm/repo
name is separate (`auto-psynet`); `skills` and `commands` are explicit arrays in `plugin.json`; agents
are auto-discovered from `agents/`; **hooks live in `hooks/hooks.json` next to the hook scripts** (not
in `.claude-plugin/`). `tests/validate-assembly.sh` asserts every listed skill/command exists and
frontmatter parses.

## 3.3 The pipeline (workflow-as-code)

`config/pipeline.yaml` declares the five stages, the agents each runs, prompt templates, transitions,
and numeric gate thresholds — the octopus `embrace.yaml` pattern. An imperative fallback in the engine
runs the same sequence if the YAML runtime is disabled. Each stage:
1. loads the experiment's `.apsy/` state + relevant memory,
2. dispatches its skill(s) → persona agent(s),
3. writes its artifact(s) into `.apsy/`,
4. runs its **gate**, and
5. consults the **autonomy level** to decide auto-advance vs. pause-for-approval.

| Stage | Skills (doc 04) | Primary persona | Artifact(s) | Gate |
|-------|-----------------|-----------------|-------------|------|
| 1 FORMULATE | formulate, design, power-analysis, analysis-plan, plan-review | methodologist + statistician | `research-plan.md` (preregistration) | **G1 Plan Verified** |
| 2 BUILD | scaffold, implement-paradigm, wire-timeline, test-experiment | psynet-engineer | PsyNet project + green bot tests | **G2 Build Verified** |
| 3 PILOT/DEPLOY | llm-pilot → deploy, recruit | psynet-engineer + data-analyst | pilot data; live deployment | **G3 Pilot Verified** → **G4 Deploy Approved** |
| 4 ANALYZE | data-quality, analyze, interpret, iterate | statistician + data-analyst | `analysis/`, `reports/` | **G5 Data Quality** → **G6 Findings Verified** → **G7 Iterate/Ship** |
| 5 PUBLISH | write-paper, repro-package | science-writer | paper draft + OSF package | (final review) |

## 3.4 Quality gates

> **User-facing companion:** [`../GATES.md`](../GATES.md) — what each gate actually checks
> (in plain English), the hard-vs-advisory model, and how gates interact with autonomy levels.
> This section is the design rationale; the rubrics are in `config/gates/*.yaml`.

Gates are scored checklists (`config/gates/*.yaml`) that consult the blind-spot library. Each returns a
verdict the pipeline acts on, and emits a `{"decision":"block"|"continue","reason":...}`-style result a
PostToolUse hook can enforce (octopus's quality-gate pattern).

| Gate | When | Checks (abridged) | If fail |
|------|------|-------------------|---------|
| **G1 Plan Verified** | end of FORMULATE | construct validity · internal validity (confounds, counterbalancing) · statistical-conclusion validity (power ≥ target, correct model, multiple-comparison handling) · novelty vs literature · feasibility in PsyNet · ethics/consent | revise plan |
| **G2 Build Verified** | end of BUILD | `psynet test local` green · every page has `time_estimate` · unique `id_`s · `bot_response` on every control · consent first · timeline matches the plan | fix code |
| **G3 Pilot Verified** | end of LLM pilot | pipeline ran end-to-end with LLM participants · no async/render errors · analysis pipeline executes on pilot data · design is doable (LLM didn't get stuck/confused) | back to BUILD |
| **G4 Deploy Approved** | before human deploy | **explicit human approval** · spend cap configured · recruiter + payment sane · IRB/ethics confirmed | **hard stop** (never auto-passed) |
| **G5 Data Quality** | after collection | attention/manipulation checks · completion · exclusion rules applied · target N reached · bot/bad-actor screen | extend recruit / re-run |
| **G6 Findings Verified** | after analysis | analysis matched preregistration · deviations logged · effect sizes + CIs reported · robustness/sensitivity ok | document / re-analyze |
| **G7 Iterate or Ship** | decision point | are we satisfied? if not, what single change and why? | loop to Stage 2/3 |

## 3.5 Per-experiment state (`.apsy/` — the source of truth)

Each experiment is its own directory/repo. State lives in files committed alongside the PsyNet code, so
it survives the days-long data-collection gap, context compaction, and the plugin being absent.

```
<experiment>/
├── experiment.py  config.txt  requirements.txt  ...   # the PsyNet project (Stage 2+)
└── .apsy/
    ├── research-plan.md     # hypotheses, design, IV/DV, power, analysis plan = the preregistration
    ├── state.json           # {stage, iteration, gate_statuses, autonomy_level, spend, deploy_target}
    ├── iteration-log.md     # per-iteration: what changed, why, what happened (the improvement trail)
    ├── decisions.md         # key decisions + rationale (paradigm choice, exclusions, deviations)
    ├── deployment-log.md    # deployments, recruitment batches, spend, timestamps
    ├── analysis/            # analysis scripts + outputs, versioned per iteration
    └── reports/             # gate reports, pilot reports, the draft paper
```

`state.json` is the resume anchor: any new session reads it (via the SessionStart hook) to know exactly
where this experiment stands. Templates live in `config/templates/`.

## 3.6 The LLM-participant harness (flagship)

Built on PsyNet's bot system (`psynet/bot.py`: `Bot`, `BotDriver`, `Control.bot_response`). Three levels
(see [`01-vision-and-scope.md`](01-vision-and-scope.md §1.4)). Mechanism for Level 1/2:

- The engine provides an **LLM participant driver** that runs a `BotDriver` whose controls' `bot_response`
  is backed by an LLM call rather than a fixed value.
- For each page the bot reaches: serialize the `Prompt` (text/markup, and a textual description of any
  media) plus the `Control`'s response affordances (e.g. the options of a `PushButtonControl`, the range
  of a `SliderControl`, the schema of a `SurveyJS` form) into a structured prompt.
- Call a Claude model with: a **participant persona** (optionally sampled from a population spec), the
  task instructions seen so far, and the current page. Require a structured answer.
- **Parse** the answer back into the exact format the control expects (validated against its schema;
  retry on malformed output) and submit it via the driver.
- Record a full transcript (page → reasoning → answer) for auditability, and write synthetic responses
  in the same shape PsyNet's export produces, so the **same analysis code runs on pilot and human data**.

This requires generated experiments to expose enough structured metadata per control for serialization
— which the BUILD stage guarantees by construction (and which also makes the experiments cleaner).
Cost is bounded (pilot N is small) and configurable. Scientific caveats for Level 2 are enforced by the
honesty guardrails in scope.

**Human-AI hybrid (Level 3).** The same driver, plugged into PsyNet's real-time synchronization
(`SyncGroups` / `sync_group_type`) and network paradigms (`GraphChainTrialMaker`), lets human and LLM
participants occupy the **same chain or network**. Async hybrid (alternating human↔AI chain links) needs
only the driver + a chain paradigm; real-time sync hybrid additionally needs the synchronization infra
and is the most advanced capability (Track A, Phase 3). Mixed-sample analysis (non-independence,
exchangeability) is handled by the `statistician` persona.

**Backend (set by `setup`).** The LLM-participant driver calls an **OpenAI or OpenRouter** API (model
chosen at setup; OpenRouter preferred for multi-model flexibility). If no key is configured, it falls
back to the **ambient Claude Code model** via subagents. Keeping the *subject* model (e.g. a GPT/o-series
or an open model via OpenRouter) distinct from the *orchestrator* (Claude Code) is also methodologically
cleaner for human-vs-LLM and hybrid studies — the researcher-AI and the subject-AI are not the same
system. Cost is capped per pilot in `state.json`. *(Precedent: the real `vibe_coding_experiment` already
calls OpenAI's `/v1/chat/completions` with a bearer key + configurable `AI_MODEL` inside a PsyNet
experiment — see [`02-reference-synthesis.md`](02-reference-synthesis.md) §2.6 — so OpenRouter is a
drop-in.)*

## 3.7 Memory layer

File-based only — **no external memory service**. (claude-mem was evaluated and declined; see [`02-reference-synthesis.md`](02-reference-synthesis.md) §2.4.)

- **Authoritative (files):** the per-experiment `.apsy/` directory + a small user-level
  `~/.auto-psynet/` (global config, cross-experiment index, API keys via env). The cross-experiment
  index is a simple registry mapping experiment IDs → paths → one-line status, so the plugin can answer
  "what have we run before?" with no external memory service.
- **Native memory (no external service):** Claude Code's own file-memory (this plugin's `MEMORY.md`) records durable
  cross-session preferences and project facts.

## 3.8 Deployment adapter (pluggable)

A single `deploy` interface in the engine with interchangeable backends, so the rest of the plugin is
deployment-agnostic (the kickoff "flexible/pluggable" decision):

| Backend | `psynet` path | Status | Use |
|---------|---------------|--------|-----|
| `local` | `psynet debug local` | **P0** | development, browser validation (needs a Docker-capable box) |
| `llm-pilot` | `BotDriver` + LLM driver (no public web needed) | **P0** | Stage 3a piloting, synthetic data |
| `ec2` | `dallinger ec2 provision` + DNS records, then deploy/debug over SSH | **P1** | provisioned cloud box (Docker+Postgres+Redis+public web): cloud **debug** *and* real deployment; resolves the HPC-Docker gap (D1) |
| `ssh` | `psynet deploy ssh --app …` | P2 | real human data on a pre-existing host we control |
| `heroku` | `psynet deploy heroku --app …` | P2 | managed real human data |

The `debug` skill surfaces a **target selector** (local vs `ec2`) over this adapter (the "debug-mode"
selection). EC2 instances are named **`{username}.{study}.{host}`** from the `setup` username + a study
abbreviation; Dallinger validates the subdomain and creates the DNS records. EC2 defaults: region
**`us-east-1`** (override `apsy:region`) and instance **`m7i.{N}xlarge`** auto-sized by the estimated
experiment size — `xlarge` (16 GB) → `2xlarge` (32 GB) → `4xlarge` (64 GB) → … (override `apsy:type`).
The adapter records every action to `deployment-log.md` and is the choke point for the G4 spend gate.

## 3.9 Runtime / environment requirements (the lab)

PsyNet needs **Docker + Postgres + Redis + a worker/clock**, and (for real recruitment) a public web
endpoint. This is the biggest environment risk and must be validated by a `/apsy:doctor` skill before
anything else.

- **Local debug + LLM-pilot (P0)** need the Docker/Postgres/Redis stack reachable from wherever the
  plugin runs, but **no public endpoint** (LLM participants connect locally). This is the minimum viable
  lab and is where the MVP lives.
- **HPC caveat + D1 resolution (NCSA Delta):** HPC nodes often restrict Docker (Apptainer/Singularity
  instead) and lack inbound public networking. **Resolved (D1):** the `ec2` backend (Dallinger
  provisioning) is the primary server path — it gives a real Docker + public-web box for *both*
  cloud-debug and deployment, sidestepping the HPC limits. Local debug stays an option where a
  Docker-capable workstation/VM exists (faster, free); otherwise the plugin runs **EC2-first**. `doctor`
  detects local-Docker availability + AWS creds and routes accordingly; `debug` lets the user pick.
- **External services:** Claude (the ambient orchestrator) + an **OpenAI/OpenRouter** key for LLM
  participants (or ambient fallback); **AWS** for `ec2` provisioning; literature APIs (arXiv / Semantic
  Scholar) for FORMULATE; **Prolific (default), Lucid, or MTurk** for recruitment (Track B); OSF API for
  the repro package (P2); a Python stats runtime (`pandas`/`scipy`/`statsmodels`/`pingouin`; R when needed).
- **Python interpreter (the "apsy python"):** resolved by `bin/apsy-common.sh:apsy_resolve_python`
  with priority `--python PATH > $VIRTUAL_ENV > $APSY_PYTHON > python3 from PATH`. **`/apsy:install`
  --create-venv** provisions a managed venv at `~/.auto-psynet/venv/` on first run and records
  `APSY_PYTHON` in `~/.auto-psynet/config` so every subsequent `/apsy:install` / `/apsy:update` /
  `/apsy:doctor` / `/apsy:check` resolves to the same interpreter. Conda / poetry / uv users opt out
  by setting `APSY_PYTHON` to their interpreter path. `bin/apsy-check.sh` is the single source of
  truth for "are the essential deps present + current?" and is consumed by both `/apsy:setup` STEP 2
  and `/apsy:doctor`.
- **Native services for local debug (verified 2026-05-28):** `psynet debug local` (the default
  `_debug_auto_reload` path) requires **Redis at `localhost:6379`** (used by `_pre_launch` in ALL 3
  debug paths) + **PostgreSQL at `localhost:5432`** with a `dallinger` superuser + `dallinger`
  database. Install priority: system (`apt install redis-server postgresql` /
  `brew install redis postgresql@14`) → conda-forge (no-root fallback) → source compile. `pip`/`uv`
  **cannot** install these (server binaries, not Python packages). `bin/apsy-doctor.sh` reports
  them as ❌ HARD when missing.
- **Project directory (`APSY_PROJECT_DIR`):** the consistent root where new experiments are
  scaffolded. Set via `/apsy:setup` (STEP 4) or `/apsy:project-dir` later. Default if unset = cwd
  (legacy). Two-pronged redirect of PsyNet's hardcoded `~/psynet-data/...` paths into the project
  tree: `bin/apsy-export.sh` auto-adds `--path $APSY_PROJECT_DIR/data/<study>` to `psynet export
  local` (per-call); `/apsy:project-dir` STEP 5 optionally symlinks `~/psynet-data` →
  `$APSY_PROJECT_DIR/data` to redirect `assets`/`launch-data`/`artifacts` transparently.
- **`psynet debug local` pre-launch fixups** (auto-handled by `bin/apsy-debug.sh local`):
  `.gitignore` (psynet rejects directories without one) · `git init` + initial commit (psynet does
  git introspection) · `constraints.txt` (via `psynet generate-constraints` from
  requirements.txt) · PATH hygiene (venv's `bin/` first so `flask`/`gunicorn` resolve to the right
  interpreter; otherwise `ModuleNotFoundError: gevent`).
- **Hot-reload behavior (verified):** werkzeug's stat reloader fires on every file change, but
  dallinger's worker subprocesses don't auto-re-import. Edits to `Exp` class config / `TrialMaker`
  subclasses / module-level imports → **restart** `bin/apsy-debug.sh local` (workers stay stale
  otherwise). Edits to method bodies / literal strings / comments / `bot_response` lambdas /
  `time_estimate` values usually hot-reload cleanly.

## 3.10 Autonomy & safety model

> **User-facing companion:** [`../AUTONOMY.md`](../AUTONOMY.md) — the three levels in plain
> English, when to use which, the four invariants that hold at every level (G4 always pauses,
> autonomy never softens HARD items, synthetic data always labeled, preregistration deviations
> always logged), and how to set/change the level via `bin/apsy-state.sh`.

- **Levels** (in `state.json`, default supervised): `supervised` (pause at every gate),
  `semi_autonomous` (auto-advance through G1–G3 and analysis, pause at G4 + final), `autonomous`
  (auto-advance all soft gates; G4 spend + ethics **always** require human approval).
- **Hard, non-overridable gates regardless of level:** G4 (real human deploy/spend) and any real-money
  action. A PreToolUse hook intercepts `psynet deploy …`, recruiter API calls, and spend operations and
  blocks unless an approval token + configured cap are present (octopus's `scheduler-security-gate`/
  `careful-check` pattern).
- **PsyNet-lint PreToolUse hook:** when editing `experiment.py`, inject the 8 code-gen gotchas and flag
  obvious violations before the file is written.
- **Capture PostToolUse hook:** after gates/tests/analysis, append outcomes to `iteration-log.md` and
  the cross-experiment file index.

## 3.11 Why this is enough (and not more)

The essential harness is: **a locked plugin manifest; skills as execution contracts; a small persona
library; a deterministic engine wrapping the real `psynet` CLI + analysis + LLM-participant driver;
file-based per-experiment state; seven gates; a handful of safety/context hooks; and a pluggable deploy
adapter that starts at local + LLM-pilot.** Everything else (MCP server, multi-LLM review,
breadth of paradigms, full autonomy, OSF/Prolific integrations) is additive and deferred — see the
roadmap. This keeps the MVP focused on the two hardest, highest-value problems: **verifying the research
plan** and **generating a PsyNet experiment that actually runs.**
