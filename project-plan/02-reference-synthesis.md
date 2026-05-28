# 02 — Reference Synthesis

What we extracted from the four reference repos (PsyNet, Dallinger, octopus, claude-mem) and precisely
what we **reuse**, **adapt**, or **avoid** for Auto-PsyNet. These are the conclusions of a deep read of
each codebase.

> **Dev-only**: during authoring, those repos sit alongside this one in `materials/` (gitignored, not
> shipped) so they can be greped locally. They are *not* dependencies of the plugin and don't appear in
> the released package; recipe references resolve against the **installed** `psynet` (`APSY_PSYNET_PATH`).

---

## 2.1 PsyNet — the build target and execution engine

PsyNet (v13.x, on top of Dallinger 11.x) is the thing the plugin generates code for and drives. It is
an unusually good code-generation target because an experiment is **one declarative `Experiment` class
plus a small, regular directory**, with variability concentrated in a few overridable methods.

**Core model (what generated code is made of):**
- `Experiment` (`psynet/experiment.py`): root class, conventionally named `Exp`. Key attributes:
  `label`, `timeline`, `initial_recruitment_size`, `test_n_bots`, `variables`, `config`.
- `Timeline` (`psynet/timeline.py`): an ordered list of `Elt`s = the entire participant experience.
- `Page` / `ModularPage` = `Prompt` (what is shown) + `Control` (how they respond); `PageMaker` =
  a page computed at runtime from participant state; `CodeBlock` = side effects; control flow via
  `conditional`, `switch`, `while_loop`, `for_loop`, `randomize`.
- `Module` = named grouping; `TrialMaker` (subclass of Module) administers a sequence of `Trial`s drawn
  from `Node`s within `Network`s.
- `Asset` = any media/generated stimulus, with pluggable storage (local/S3/web).
- ORM-backed (SQLAlchemy/Dallinger): subclassing auto-registers polymorphic identity, so a custom
  `MyTrial` just works and exports to its own table.

**Paradigms available out of the box (= our `TrialMaker` palette):** `StaticTrialMaker` (fixed stimulus
set, blocks, balancing — the most common), `ImitationChainTrialMaker` (iterated learning / transmission
chains), `GibbsTrialMaker` + media variants (GSP), `MCMCPTrialMaker` (MCMC with people),
`GraphChainTrialMaker`, `GeometricStaircaseTrialMaker` (adaptive psychophysics), `DenseTrialMaker`
(dense rating / AXB / same-different), and the `CreateAndRate` mixin. **Design implication:** Stage-1
paradigm selection is fundamentally a mapping from research-design features → one of these classes; the
plugin should own that mapping table explicitly.

**Batteries we compose (do not reinvent):** consent modules (`MainConsent`, `OpenScienceConsent`, …);
demography (`Age`, `Gender`, `BasicDemography`, the `GMSI`/`PEI` instruments); prescreening
(`AttentionTest`, `ColorBlindnessTest`, `HeadphoneTest`, `LexTaleTest`, REPP calibration, vocab tests).

**Lifecycle / CLI (what the engine layer wraps):** `psynet debug local` (dev), `psynet debug
ssh/heroku` (cloud test w/o recruitment), `psynet deploy ssh/heroku` (real), `psynet export
local/ssh/heroku`, `psynet test local` (bots), `psynet estimate`, `psynet update-scripts` (scaffold
boilerplate), `psynet generate-constraints`. Infrastructure: **Docker + Postgres + Redis + a worker
clock**, and a public web endpoint for recruitment.

**Data:** `psynet export` produces, per deployment, `database.zip` (Dallinger format, re-ingestable to
reconstruct ORM state), `data/` (one CSV per most-specific class, e.g. `MyTrial.csv` with `definition`,
`answer`, `score`, `node_id`, `participant_id`, `trial_maker_id`, `failed`, …), `assets/`, `logs.jsonl`,
and `source_code.zip`, in both `regular/` and PII-scrubbed `anonymous/` variants. **The analysis stage
reads `data/*.csv` (or re-ingests `database.zip`).**

**Bots / testing (the basis for LLM-piloting):** `Bot(Participant)` + `BotDriver` run a participant
without a browser; every `Control` takes a `bot_response` (value or lambda receiving `bot`/`self`). A
custom control with no `bot_response` raises `NotImplementedError` under test. `test_n_bots` and
`test_check_bot()` on the `Exp` class make the experiment self-verifying end-to-end.

**Code-generation gotchas the BUILD stage must respect** (these become hard rules in the PsyNet-engineer
agent and a PreToolUse lint hook):
1. Every `Page`/`PageMaker` needs a `time_estimate`; every `Trial` subclass needs a `time_estimate`.
2. All `Module`/`TrialMaker` `id_`s must be globally unique in the timeline.
3. The same object instance cannot appear twice in a timeline — use factory functions in loops.
4. Supply `bot_response` on every control or bot tests fail.
5. `static` uses `nodes=`; chains use `start_nodes=` (list for `"across"`, lambda for `"within"`).
6. Use `markupsafe.Markup`/`dominate` for HTML in prompts (plain strings are escaped).
7. Consent goes first; the recruiter validates its presence.
8. Generate `experiment.py` + `config.txt` + `requirements.txt`, then run `psynet update-scripts` to
   fill the `docker/`, `Dockerfile`, `test.py`, `pytest.ini` boilerplate from
   `psynet/resources/experiment_scripts/`.

**What we reuse:** all of it — PsyNet *is* the instrument. **Avoid:** hand-writing the boilerplate the
CLI generates; reinventing consent/demography/prescreen modules.

---

## 2.2 Dallinger — the substrate (mostly transparent)

Dallinger provides the laboratory-automation layer PsyNet sits on: experiment server, participant model,
recruiter abstraction (Prolific, MTurk, CAP, Lucid, plus `generic`/`hotair` for dev), MTurk/Prolific
plumbing, Docker-based deployment to Heroku or SSH hosts, and the data export format. We interact with
it **only through PsyNet** and the `psynet`/`dallinger` CLIs. **Reuse:** recruiter abstraction and
deploy targets (informs our deployment adapter). **Avoid:** touching Dallinger internals directly.

---

## 2.3 octopus — the architecture template (patterns, not code)

A mature, production Claude Code plugin (54 skills, 32 personas, 48 commands, 56 hooks, an MCP server,
a 2994-line `orchestrate.sh` engine). We are **not forking it**; we are copying its proven *structure*.

**Patterns we reuse (high value):**
- **Manifest discipline.** Short plugin `name` that doubles as the command namespace (`octo` → `/octo:*`);
  it is *locked* (a `PLUGIN_NAME_LOCK.md` + a validation test) and kept deliberately distinct from the
  npm/repo name. Explicit `skills`/`commands` arrays in `.claude-plugin/plugin.json`; agents
  auto-discovered from `.claude/agents/`; hooks in a separate `.claude-plugin/hooks.json`. A
  `validate-plugin-assembly` smoke test checks everything coheres. → We adopt all of this with `apsy`.
- **Skill = blocking EXECUTION CONTRACT.** Skills are numbered, mandatory step machines with
  per-step "DO NOT PROCEED until X" gates + rationale, `<HARD-GATE>` blocks, explicit "PROHIBITED FROM"
  lists, **artifact-existence validation** ("fail loud, never silently fall back"), and a "STOP — skill
  already loaded, do not re-dispatch" guard. The `description` field is the auto-trigger ("Do X — use
  when Y"). → This is exactly the rigor a *scientific* workflow needs; we adopt the contract style
  wholesale.
- **Conductor / instrument split.** Skills/commands orchestrate; one engine (`orchestrate.sh` + ~60
  sourced `lib/` modules) does the work. → Our engine wraps the `psynet` CLI + analysis runners + APIs.
- **Persona library + routing registry.** Portable expert system-prompts (`agents/personas/*.md` with
  `when_to_use`/`avoid_if`/`examples`) bound to phases/models by a central `agents/config.yaml`, each
  with a structured `COMPLETE | BLOCKED | PARTIAL` Output Contract. → We build a research-persona
  library (methodologist, statistician, PsyNet-engineer, …).
- **Workflow-as-code + imperative fallback.** A declarative phase YAML (`embrace.yaml`: per-phase
  agents, prompt templates, transitions, **numeric quality-gate thresholds**) with an imperative
  fallback and a runtime switch. → Our 5-stage pipeline is defined the same way.
- **Quality / consensus gates + the "Dark Factory" holdout loop.** Numeric per-phase thresholds;
  cross-provider adversarial debate between phases; and a spec→holdout→blind-grade→weighted-score→
  auto-retry loop. → Maps almost perfectly to science: **research plan = spec**, **preregistered
  analysis = holdout**, **gate scores = methodological rubric**, **iterate-until-satisfied = retry loop.**
- **Hooks for autonomy & safety.** SessionStart context/router injection; PreToolUse safety gates with
  `if`/regex guards and "careful"/"freeze" modes; PostToolUse quality gates returning
  `{"decision":"block"}`; lifecycle hooks (SubagentStop/TaskCompleted/PreCompact) for resumable
  autonomy; a uniform stderr exit trap. → We reuse this for spend-safety, PsyNet-lint, and gate enforcement.
- **File-based state outside the plugin dir** (`~/.claude-octopus/`) for resume + compaction-resistance;
  strict "no working files in the plugin dir" policy. → We keep authoritative state *in each experiment
  repo* (`.apsy/`) plus a small user-level config dir.
- **Blind-spot library** (`config/blind-spots/`: keyword-triggered injectable "things LLMs miss"). →
  Re-skinned as methodological/statistical pitfalls for behavioral research.
- **Thin MCP wrapper** delegating to the engine, opt-in via env flag, with env-var allowlisting and
  secret redaction. → Our optional MCP server follows the same thin-delegation, opt-in shape.

**What we deliberately do NOT take:** the multi-provider machinery (Codex/Gemini/Copilot/Qwen/…), the
cross-platform transpilation to Codex/Cursor/Factory, and the sheer surface area (54 skills). We are
Claude-native and start small. (Multi-LLM adversarial review is a *possible later* feature, per the
kickoff's third option — but not the default.)

**Reference files to model from:** `skills/flow-discover/SKILL.md`, `skills/skill-factory/SKILL.md`
(skill contracts); `.claude/commands/auto.md` (router); `scripts/lib/workflows.sh`,
`scripts/lib/factory.sh` (pipeline + scoring); `config/workflows/embrace.yaml` (workflow-as-code);
`agents/config.yaml` (routing); `.claude-plugin/{plugin,hooks}.json`; `mcp-server/src/index.ts`.

---

## 2.4 claude-mem — evaluated, NOT adopted

> **Decision: NOT adopted.** Memory is **file-based only** (the per-experiment `.apsy/` directory +
> Claude Code's native file-memory); claude-mem is **not a dependency**. The analysis below is kept as
> design rationale for why an external memory service was evaluated and declined.

A persistent-memory-compression system for Claude Code (SQLite + FTS5, optional Chroma vectors; a
background worker captures tool events on `PostToolUse`/`Stop`, an LLM compresses them into typed
`observations` + per-session summaries, and `SessionStart` injects recent project memory back).

**What is genuinely valuable for us:**
- Automatic, passive capture of what the agent did each session → useful for "what did we try in
  experiment X across these days."
- **FTS5 search across all past sessions/experiments**, and especially **knowledge corpora**
  (`build_corpus`/`prime_corpus`/`query_corpus`) — "build a brain about all our stimulus-design
  decisions and ask it questions." This is the standout reusable feature for cross-experiment knowledge.
- A 3-layer, token-efficient retrieval workflow (`search` → `timeline` → `get_observations`).

**Critical caveats found in the code (these shape our integration):**
- **Project scoping is weak:** `project = basename(cwd)`. Many experiment dirs named `pilot`/`run1`
  will collide; renaming/moving forks the memory. → We must give each experiment a unique dir basename
  (or set `CLAUDE_MEM_DATA_DIR` per experiment) and always pass explicit `project=` filters.
- **No supported structured-write API in default mode.** octopus's own `observe` write path is stale
  and likely 404s against current claude-mem; the read/search path still works. → We must **not** rely
  on writing hand-authored memory through claude-mem in the default runtime.
- **Heavy runtime** (a persistent Bun worker on a per-user port, optionally a Python/Chroma process) —
  real operational surface for a possibly-headless HPC environment.

**Decision (hybrid, exactly as octopus does it):**
1. **Own authoritative state in files we control** — the per-experiment `.apsy/` directory (plan,
   iteration log, decisions, deployment/spend log). This is durable, greppable, git-versioned, survives
   claude-mem being absent, and gives us a real experiment-ID namespace. **Source of truth.**
2. **Layer claude-mem as optional enrichment** via a thin, fault-tolerant bridge (copy octopus's
   `claude-mem-bridge.sh` pattern: detect → HTTP → silently no-op on failure) for cross-experiment
   *search* and *knowledge corpora*. Let its passive capture record activity for free.
3. **Do not depend on writing structured observations through it** in default mode; if we later need
   guaranteed structured cross-project memory, evaluate its opt-in Postgres "server-beta" runtime.

**Reuse:** the bridge pattern, FTS5 search, knowledge corpora. **Avoid:** making it the source of
truth; relying on its write API; assuming `basename(cwd)` project scoping is safe.

---

## 2.5 One-line takeaways

| Repo | Role for us | One-line takeaway |
|------|-------------|-------------------|
| **PsyNet** | The instrument we generate + drive | Regular, declarative target; reuse its paradigms + batteries; respect 8 code-gen gotchas; drive its real CLI. |
| **Dallinger** | Transparent substrate | Touch only via PsyNet; informs the deployment/recruiter adapter. |
| **octopus** | Architecture template | Copy the *structure* (skill contracts, persona registry, gated pipeline, hooks, holdout loop, file-state) — not the multi-provider scope. |
| **claude-mem** | Evaluated, **not adopted** | Memory is file-based only (`.apsy/` + native Claude Code memory); claude-mem is not a dependency. |

---

## 2.6 Real experiment examples (`experiment-examples/`, dev-only)

Beyond PsyNet's bundled `demos/`, the dev tree includes two **real** experiments (Jacoby lab, Cornell)
that serve as higher-fidelity codegen references for authoring. Like `materials/`, this directory is
gitignored and not shipped — it informs how the `psynet-engineer` persona and BUILD-stage skills are
written, but the released plugin contains no copies of these experiments.

- **`create_and_rate_basic/`** — a Create-and-Rate study. Reference for: a real **custom consent**
  (`consent_science_of_learning.py` — a `(Module, Consent)` subclass taking `DURATION`/`PAYMENT`, i18n via
  `_p()`, full **Cornell IRB** boilerplate, a `PushButtonControl` consent + `RejectedConsentPage`, placed
  first in the timeline); the **Prolific config pattern** (`get_prolific_settings()` →
  `recruiter`/`base_payment`/`prolific_estimated_completion_minutes`/`prolific_recruitment_config` from
  `qualification_prolific_en.json`/**`wage_per_hour: 10`**, merged into `Exp.config`); and a modular layout
  (`info_pages.py`, `utils.py`, `simulate_experiment.py`, `run_bots_parallel.py`).
- **`vibe_coding_experiment/`** — a real **human-AI** experiment: participants interact with an LLM
  (PLANNER/CODER/REVIEWER roles) via `ai_service.py`, which calls the **OpenAI `/v1/chat/completions`**
  endpoint with a bearer key + configurable `AI_MODEL`, using Redis for async progress. Direct precedent
  for our **LLM-participant driver + human-AI hybrid harness**, and it validates the **OpenAI/OpenRouter**
  backend choice (OpenRouter is drop-in compatible with that endpoint shape).

These confirm the codegen patterns (consent-first timeline; a `config` dict with `wage_per_hour`; separate
modules; `simulate_experiment.py`/bot runners) and that an external LLM integrates cleanly into a PsyNet
experiment over plain HTTP — the `psynet-engineer` persona and the relevant skills should cite them.
