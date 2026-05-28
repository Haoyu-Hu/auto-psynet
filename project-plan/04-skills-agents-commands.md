# 04 — Skills, Agents, Commands, Hooks

The concrete "skill set" the kickoff asked for. Everything is prioritized:

- **P0** = required for the MVP (idea → verified plan → built experiment → LLM pilot → synthetic
  analysis, supervised, local).
- **P1** = required for the first real human study (deploy, recruit, real analysis, iterate).
- **P2** = breadth, polish, autonomy, integrations.

Skills follow the octopus **EXECUTION CONTRACT** style: a trigger `description`, numbered mandatory
steps, per-step gates with rationale, explicit "PROHIBITED FROM" lists, and artifact-existence
validation ("fail loud"). Skills orchestrate; the **engine** does the work; **personas** supply expertise.

## 4.0 The PsyNet Knowledge Pack (the differentiation engine)

Confirmed at design review: a **two-layer knowledge pack**, packaged as reference files **consulted by
skills + personas** (not a proliferation of auto-triggered skills), keyed off the paradigm locked at G1.
This is where the plugin's novelty value lives — it is what makes PsyNet's hard, differentiating
paradigms accessible. All four PsyNet differentiators below are **headline capabilities** (chains,
networks, cross-cultural/multilingual, human-AI hybrid); static trials are the stepping stone that
proves the loop, not the destination.

**Layer 1 — Paradigm Recipe Library (`skills/psynet/psynet-function/`, indexed by the `apsy:psynet` skill; primary).** One recipe per PsyNet paradigm
family. Each recipe documents: *when to use it · design parameters · the exact `Trial`/`Node`/
`TrialMaker` classes + overrides to write · `bot_response` patterns · gotchas · a worked example from
`demos/` · how its data exports for analysis.* The `design` skill uses these for selection; the
`implement-paradigm` skill loads the chosen one for codegen.

| Recipe | PsyNet class | Headline? |
|--------|--------------|-----------|
| static / stimulus-set | `StaticTrialMaker` | (MVP base) |
| Gibbs Sampling with People (+ media/audio) | `GibbsTrialMaker`, `*GibbsTrialMaker` | ★ **flagship** (perception) |
| MCMCP | `MCMCPTrialMaker` | ★ (perception, close 2nd) |
| transmission chain (iterated learning) | `ImitationChainTrialMaker` | ★ |
| network / graph chain | `GraphChainTrialMaker` (+ `SyncGroups`) | ★ |
| adaptive psychophysics | `GeometricStaircaseTrialMaker` | |
| dense rating (AXB / same-diff / slider) | `DenseTrialMaker` | |
| create-and-rate | `CreateAndRate` mixin | |

**Layer 2 — Domain Design-Priors (`config/domains/`, thinner, complementary).** Per behavioral domain:
typical constructs/measures, standard paradigms in that subfield, common confounds/controls, ballpark
effect sizes, key prior-work pointers. Consulted in FORMULATE. Kept lean and **demand-driven** — seeded
with the user's subfields (**perception & psychophysics, music & audio cognition, language &
communication, memory/learning/decision-making**), expanded as needed; deliberately *not* an enumeration
of all of behavioral science (that would overlap the `methodologist` persona and bloat).

**Paradigm↔domain affinity (what links the two layers).** The layers are cross-linked by a
**question-archetype affinity**, because the right paradigm is determined less by the broad domain than
by the *kind of question* asked: *"recover the mental representation / prior / prototype people hold"* →
GSP/MCMCP (clusters in perception); *"how does content transform as it's transmitted"* → transmission
chains (language/culture/memory); *"interaction / coordination / collective behavior"* → network
paradigms (social); *"measure a threshold"* → staircase/dense (psychophysics). Each paradigm recipe
carries `canonical_questions` + `canonical_domains` + `novel_but_valid_for`; each domain prior carries
ranked `typical_paradigms`; a small `config/affinity.yaml` holds the weighted many-to-many matrix the
`design` skill queries. **It is a soft prior, not a rule:** `design` surfaces the canonical match *and*
flags a defensible *novel cross-over* when one exists (e.g. GSP applied to moral judgments) — a deliberate
novelty source, not a constraint.

**Proactive design intelligence (signature behavior).** Because `design` knows the full paradigm
palette, it doesn't just implement what's asked — it can **propose elevating a design to a
differentiating paradigm** ("this one-shot color-naming rating could be a cross-cultural GSP chain —
more powerful and more novel"). Surfaced as a suggestion the researcher accepts or declines at G1.

**Cross-cutting capabilities** (woven across stages — neither a paradigm nor a domain):
- **Global / multilingual** — i18n (`psynet translate`), locale handling, global panels (Lucid).
  Touches FORMULATE (population/language scoping), BUILD (the `localize` skill), DEPLOY (global
  recruiters), and ANALYZE, where it adds a first-class check: **measurement invariance** (you cannot
  compare a construct across cultures without it) — encoded as a gate + blind-spot.
- **Human-AI hybrid / collaborative** — the synergy of the LLM-participant harness ([`03-architecture.md`](03-architecture.md) §3.6)
  and the network/sync paradigms (`SyncGroups`, `sync_group_type`): humans and LLM agents in the same
  chain or network. Async hybrid (alternating human↔AI chains) is reachable early; real-time sync hybrid
  is advanced. Requires mixed-sample analysis support (non-independence, exchangeability).

## 4.1 Skills (by stage)

### Stage 1 — FORMULATE  → gate G1

| Skill | Pri | Purpose / what it orchestrates | Key output |
|-------|-----|--------------------------------|-----------|
| `formulate` | **P0** | Turn a raw idea into a structured research question + falsifiable hypotheses; operationalize constructs into IV/DV and candidate measures/stimuli. Interactively fills gaps. | `research-plan.md` (draft: question, hypotheses, variables) |
| `literature-ground` | P1 | Search literature (arXiv/Semantic Scholar), situate the idea, find prior paradigms + expected effect sizes, argue novelty. | plan §Background + references |
| `design` | **P0** | Choose the paradigm from the Paradigm Recipe Library (§4.0; → a PsyNet `TrialMaker`); specify conditions, within/between, counterbalancing, randomization, prescreens, exclusion rules, and **target population/languages** (cross-cultural scoping). Exercises proactive design intelligence: may propose elevating to a differentiating paradigm. | plan §Design |
| `power-analysis` | **P0** | Compute required N (analytic via `pwr`, or simulation-based) for the target effect + model; produce a sensitivity curve. Runs real stats code. | plan §Power + N |
| `analysis-plan` | **P0** | Lock the statistical model, primary/secondary outcomes, and decision rules **before data** (the preregistration / "holdout"). | plan §Analysis (locked) |
| `plan-review` | **P0** | Run gate **G1**: score the plan on the methodological rubric (consults blind-spots), surface confounds/validity/ethics issues, require fixes. Optionally adversarial (multi-pass). | `reports/G1-plan-review.md`; gate verdict |

### Stage 2 — BUILD  → gate G2

| Skill | Pri | Purpose | Key output |
|-------|-----|---------|-----------|
| `scaffold` | **P0** | Generate the PsyNet project skeleton (`experiment.py`, `config.txt`, `requirements.txt`) and run `psynet update-scripts` to fill boilerplate. Sets `label`, recruiter, `wage_per_hour`, spend caps. | runnable project skeleton |
| `implement-paradigm` | **P0** | Write the `Trial`/`Node`/`TrialMaker` subclasses for the chosen paradigm from the plan; respect the 8 PsyNet gotchas; wire `bot_response` on every control. | paradigm code |
| `wire-timeline` | **P0** | Assemble the timeline: consent → instructions → prescreens → demography → trial maker(s) → feedback → debrief, composing PsyNet's built-in modules. Consent defaults to `MainConsent` (override via `apsy:consent`). | complete `timeline` |
| `generate-stimuli` | P1 | Create/source/organize the stimulus set (text/audio/image), or wire `synth_function` for generative paradigms (e.g. media-GSP); register as PsyNet `Asset`s. | `assets/` + nodes |
| `localize` | P1 | Make the experiment multilingual: extract translatable strings, run `psynet translate`, handle locales, prepare per-language stimuli. The build-side of the global/cross-cultural capability. | translated experiment |
| `test-experiment` | **P0** | Set `test_n_bots` + `test_check_bot`; run `psynet test local`; fix until green. Gate **G2**. | green bot tests; `reports/G2-build.md` |

### Stage 3 — PILOT & DEPLOY  → gates G3, G4

| Skill | Pri | Purpose | Key output |
|-------|-----|---------|-----------|
| `llm-pilot` | **P0** | Run the experiment with LLM-agent participants (§3.6 engine driver); collect synthetic data; confirm pipeline + analysis run end-to-end; sanity-check doability. Gate **G3**. | pilot dataset + `reports/G3-pilot.md` |
| `debug` | **P0** | The **debug-mode selector**: choose the target (local `psynet debug local`, or a Dallinger-provisioned **EC2** instance for cloud debug) via `AskUserQuestion`, then run it; validate the experience in-browser; catch render/async issues bots miss. | validated run (local or EC2) |
| `deploy` | P1 | Deploy via the pluggable adapter (ssh/heroku). Behind **hard gate G4** (human approval + spend cap). Records to `deployment-log.md`. | live deployment |
| `recruit` | P1 | Configure + launch + monitor recruitment (Prolific/MTurk); track completion + spend live; enforce caps. | recruited sample |

### Stage 4 — ANALYZE  → gates G5, G6, G7

| Skill | Pri | Purpose | Key output |
|-------|-----|---------|-----------|
| `export-data` | **P0** | `psynet export` (or re-ingest `database.zip`); load `data/*.csv` into the analysis environment. (P0 because it also consumes LLM-pilot data.) | tidy dataset |
| `data-quality` | P1 | Apply attention/manipulation checks, completion, preregistered exclusions, bot/bad-actor screen. Gate **G5**. | clean dataset + `reports/G5-quality.md` |
| `analyze` | **P0** | Execute the **preregistered** analysis exactly (real stats); compute effects + CIs; generate figures. Flag/justify any deviation. | `analysis/` results + figures |
| `interpret` | **P0** | Map results to hypotheses; report effect sizes, uncertainty, robustness. Gate **G6**. | `reports/G6-findings.md` |
| `iterate` | P1 | Gate **G7**: decide ship vs. iterate; if iterate, specify the single change + rationale and loop to Stage 2/3 with the trail recorded. | updated `iteration-log.md` |

### Stage 5 — PUBLISH

| Skill | Pri | Purpose | Key output |
|-------|-----|---------|-----------|
| `write-paper` | P1 | Assemble the paper: Methods auto-derived from the actual pipeline + plan, Results from the analysis, Intro/Discussion from literature + findings, figures/tables. | paper draft |
| `repro-package` | P2 | Bundle code + (anonymized) data + analysis + preregistration into an OSF-ready reproducibility package; optional OSF push. | repro package |

### Cross-cutting

| Skill | Pri | Purpose |
|-------|-----|---------|
| `setup` | **P0** | First-run configuration (octopus `/octo:setup` analog): detect an **OpenAI / OpenRouter** API key; if none, ask whether to use the **ambient Claude Code model** (LLM participants driven via subagents) or set a key + pick the model that backs **LLM participants** (and any second-opinion "discussion"); capture the **username** used as the server-name prefix (`{username}.{study}.{host}`), the base domain, and AWS creds for EC2. If no consent is configured, note the default (`MainConsent`) and point to `apsy:consent`. Writes `~/.auto-psynet/config`. | configured backend + identity |
| `doctor` | **P0** | Validate the runtime: Docker/Postgres/Redis, `psynet` install + version, LLM-participant key (OpenAI/OpenRouter) or ambient fallback, **AWS creds for EC2** + deployment-backend reachability, and essential-dependency detection. The first thing run; gives an actionable checklist. |
| `status` | **P0** | Read `.apsy/state.json` and report exactly where this experiment stands (stage, iteration, gates, spend, next action). The resume entry point. |
| `recall` | P2 | Query the cross-experiment memory (file-based index) for prior decisions/lessons. |

## 4.2 Agents / personas (the expert brains)

A small persona library (octopus `agents/personas/*.md` + `config.yaml` routing). Each is a portable
system prompt with `when_to_use` / `avoid_if` / `examples` and a `COMPLETE | BLOCKED | PARTIAL` Output
Contract. Bound to stages and models via `agents/config.yaml`.

| Persona | Pri | Expertise | Used in |
|---------|-----|-----------|---------|
| `methodologist` | **P0** | Experimental design, validity, confounds, counterbalancing, paradigm selection, ethics. | FORMULATE, gates |
| `statistician` | **P0** | Power analysis, model choice, preregistered analysis, multiple comparisons, effect sizes, robustness, and **cross-cultural measurement invariance** + mixed human-AI-sample modeling. | FORMULATE, ANALYZE |
| `psynet-engineer` | **P0** | Deep PsyNet/Dallinger code generation: paradigms, timeline, controls, assets, bots, the 8 gotchas, CLI. **Owns the Paradigm Recipe Library**, incl. chains, network/graph + `SyncGroups`, and i18n. | BUILD, PILOT |
| `data-analyst` | P1 | Data wrangling, cleaning, exclusions, visualization, the analysis runner. | ANALYZE |
| `literature-scholar` | P1 | Literature search, novelty, situating contribution, expected effects, citations. | FORMULATE, PUBLISH |
| `science-writer` | P1 | Academic writing: Methods/Results/Intro/Discussion, figures, reproducibility. | PUBLISH |
| `adversarial-reviewer` | P2 | Red-team designs, stats, and claims (octopus debate-gate pattern; multi-LLM optional). | gates G1/G6 |
| `code-reviewer` / `debugger` | P1 | Review/fix generated PsyNet code and analysis scripts (reuse octopus-style agents). | BUILD, ANALYZE |

## 4.3 Slash commands

Thin entry points (octopus command style: gather input via `AskUserQuestion`, then invoke skills /
engine). Namespace `/apsy:*` (locked = plugin name).

| Command | Pri | Maps to |
|---------|-----|---------|
| `/apsy:setup` | **P0** | **the entry point** — first-run config: pick Python interpreter (optionally create managed venv at `~/.auto-psynet/venv` + record `APSY_PYTHON`), run dep + version check (`apsy-check`), offer `/apsy:install` on missing, configure LLM-participant backend + username + AWS + base domain + consent default. **The SessionStart `first-run-nudge` hook redirects users here on first session.** |
| `/apsy:install` | **P0** | auto-install essential deps (`psynet` + `dallinger` + optional Python stats stack) with optional version pinning. Owns the venv/interpreter decision (`--create-venv` / `--python PATH`). Records `APSY_PYTHON`, `APSY_PSYNET_VERSION`, `APSY_DALLINGER_VERSION`, `APSY_PSYNET_PATH`. |
| `/apsy:update` | **P0** | upgrade PsyNet / Dallinger to specified or latest. Reuses the install engine via `--upgrade`; prints `old → new` diff; warns on project-pin desync. |
| `/apsy:project-dir` | **P0** | set or inspect `APSY_PROJECT_DIR` — the consistent root where new experiments are scaffolded. Default if unset: current working directory. Optionally symlinks `~/psynet-data` → `$APSY_PROJECT_DIR/data` to redirect PsyNet's hardcoded `assets`/`launch-data`/`artifacts` paths transparently. |
| `/apsy:doctor` | **P0** | environment validation — reports the resolved "apsy python" + source, delegates the dep/version section to `apsy-check`, checks Redis + Postgres reachable (HARD — required for `psynet debug local`), reports `APSY_PROJECT_DIR` writability, LLM key, AWS, config. |
| `/apsy:status` | **P0** | where am I (reads `<exp>/.apsy/state.json`) |
| `/apsy:idea <text>` | **P0** | start FORMULATE (formulate → design → power → analysis-plan → plan-review) |
| `/apsy:build` | **P0** | run BUILD (scaffold → implement → wire-timeline → test) |
| `/apsy:debug` | **P0** | debug-mode selector: run locally or on a provisioned EC2 instance |
| `/apsy:pilot` | **P0** | run llm-pilot (+ `debug`), gate G3 |
| `/apsy:analyze` | **P0** | export → (quality) → analyze → interpret |
| `/apsy:deploy` | P1 | gated human deploy + recruit (G4 HARD at every autonomy level) |
| `/apsy:paper` | P1 | write-paper (+ repro-package) |
| `/apsy:auto [text]` | P1 | smart router: NL intent → right stage/skill (rule-based, stage-aware) |
| `/apsy:run <idea>` | P2 | autonomous full pipeline (idea → paper), honoring autonomy level + hard gates |
| `/apsy:add-recipe` | P1 | extend the PsyNet knowledge pack — add a new file under `skills/psynet/psynet-function/` (paradigm or cross-cutting) and auto-insert a row into the parent index table |
| `/apsy:region` | P1 | override the AWS region for EC2 (default `us-east-1`) |
| `/apsy:type` | P1 | override the EC2 instance type (default auto-sized `m7i.{N}xlarge`) |
| `/apsy:consent` | P1 | set the consent (default PsyNet `MainConsent`): separate-file path? · class/function to import · how to use it |
| `/apsy:prolific` | P1 | set compensation (default `wage_per_hour=10`) + Prolific params (base_payment, est. minutes, qualification JSON) |
| `/apsy:lucid` | P1 | set Lucid recruiter params (global panels) |
| `/apsy:mturk` | P1 | set MTurk recruiter params |

## 4.4 Hooks

Wired in **`hooks/hooks.json`** (next to the hook scripts; not in `.claude-plugin/`). Conventions:
matchers with regex guards, JSON `{"hookSpecificOutput":...}` returns, uniform exit handling.

| Event | Hook | Pri | Status | Does |
|-------|------|-----|--------|------|
| SessionStart | `load-experiment-context` | **P0** | shipped | If in an experiment dir, inject `.apsy/state.json` + recent `iteration-log.md`. Makes sessions resumable across the data-collection gap. |
| SessionStart | `first-run-nudge` | **P0** | shipped | When `~/.auto-psynet/config` doesn't exist, emit an `additionalContext` recommending `/apsy:setup`. Silent forever once setup is complete. **Ties `/apsy:setup` as the start of the plugin.** |
| PreToolUse (Edit/Write/MultiEdit on `experiment.py`) | `psynet-lint` | **P0** | shipped | Inject the 8 code-gen gotchas; flag obvious violations (missing `time_estimate`, duplicate `id_`, missing `bot_response`) before write. |
| PreToolUse (Bash: `psynet deploy`, recruiter/API, spend) | `spend-gate` | **P0** | shipped | **Hard block** real deploy/recruit/payment unless `APSY_DEPLOY_APPROVED=1` (set only by `/apsy:deploy` after G4) + configured cap are present. Never auto-passed. |
| SessionStart | `router-inject` | P2 | planned | Inject the `/apsy:auto` routing contract (deferred; the existing router skill already handles this on-demand). |
| PostToolUse (after `psynet test`/gate/analysis) | `quality-gate` | P1 | planned | Parse the gate/test result; block on failure; append outcome to `iteration-log.md`. |
| PostToolUse (`*`) | `capture` | P2 | planned | Append durable outcomes to the `.apsy/` state files. |
| SessionEnd | `snapshot-state` | P1 | planned | Flush `.apsy/state.json`; record next action. |

## 4.5 MCP server (optional, P2)

A thin, opt-in (env-flag) MCP server delegating to the engine (octopus's thin-wrapper pattern), useful
once the CLI engine is stable. Candidate tools: `psynet_validate` (lint an `experiment.py` against the
gotchas + introspect available paradigms/controls/prescreens), `power_calc`, `lit_search`,
`recruit_status` (Prolific), `experiment_status` (read `.apsy/state.json`). Not required for the MVP —
skills shelling out to `bin/apsy-*` cover all of this first.

## 4.6 Config-as-data (not code)

These live in `config/` so methodology + domain knowledge are editable without touching skill logic:
- *Paradigm recipes are not in `config/`* — they live in **`skills/psynet/psynet-function/`** (indexed by
  the `apsy:psynet` skill; §4.0). The `affinity.yaml` selector stays in `config/`.
- `domains/*.md` — the **Domain Design-Priors** (§4.0): thin, demand-driven per-subfield framing knowledge.
- `gates/G*.yaml` — the seven gate rubrics (scored checklists), incl. measurement-invariance for cross-cultural.
- `blind-spots/*.yaml` — methodological/statistical pitfall library, keyword-triggered into gates.
- `pipeline.yaml` — the 5-stage workflow-as-code (agents, prompts, transitions, thresholds).
- `templates/` — `.apsy/` state files + experiment scaffolds.

## 4.7 MVP skill surface (what to build first)

The smallest coherent set that delivers the core loop end-to-end on synthetic data, locally, supervised:

**Skills:** `setup`, `doctor`, `formulate`, `design`, `power-analysis`, `analysis-plan`, `plan-review`,
`scaffold`, `implement-paradigm`, `wire-timeline`, `test-experiment`, `llm-pilot`, `debug`,
`export-data`, `analyze`, `interpret`, `status`, and the `psynet` knowledge skill.
**Personas:** `methodologist`, `statistician`, `psynet-engineer`.
**Commands:** `/apsy:setup`, `/apsy:doctor`, `/apsy:idea`, `/apsy:build`, `/apsy:debug`, `/apsy:pilot`, `/apsy:analyze`, `/apsy:status`.
**Hooks:** `load-experiment-context`, `psynet-lint`, `spend-gate` (active even pre-deploy, as a safety net).
**PsyNet knowledge:** `skills/psynet/` (the `apsy:psynet` index + `psynet-function/` recipes — all 8
paradigms + cross-cutting functions authored; the MVP exercises `static` first, then GSP); `gates/G1`–`G3`+`G6`;
a starter `blind-spots/` set (including measurement-invariance); `.apsy/` templates.
**Scope of paradigms in MVP:** **static trials only** (cleanest template) to prove the loop mechanics —
explicitly a stepping stone. The recipe library is structured so the **flagship GSP recipe**
(`GibbsTrialMaker`, anchored on perception/mental-representations; MCMCP close behind) is the immediate
next target, followed by the other headline differentiators (transmission chains, network/`SyncGroups`,
cross-cultural, human-AI hybrid). See [`05-roadmap.md`](05-roadmap.md) for the differentiator sequencing.
