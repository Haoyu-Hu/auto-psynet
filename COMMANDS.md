# Auto-PsyNet — command reference

A user-facing catalog of every `/apsy:*` command: what it does, how to invoke it, what it
produces, and which quality gate (if any) it triggers. Live, in-CLI version: `/apsy:help` (no
args) or `/apsy:help <name>` for a single command. The authoritative source for each command's
*orchestration steps* is its `commands/<name>.md` file; this document is the user-level synthesis.

**Conventions**
- `$ARGUMENTS` — whatever the user types after the command (e.g. `/apsy:install --psynet 13.2.0`).
- `~/.auto-psynet/config` — user-level config (LLM backend, `APSY_PROJECT_DIR`, AWS, …).
- `<experiment>/.apsy/` — per-experiment state (plan, `state.json`, decisions, reports).
- Gates **G1–G7** are defined in [`config/gates/`](config/gates/); ethics policy in
  [`config/ethics-policy.md`](config/ethics-policy.md).

## Table of contents

- [Bootstrap & install](#bootstrap--install) — `setup`, `install`, `update`
- [Discovery & environment](#discovery--environment) — `help`, `status`, `doctor`,
  `project-dir`, `services`
- [Pipeline](#pipeline) — `idea` (G1) · `build` (G2) · `pilot` (G3) · `debug` · `export` ·
  `deploy` (G4) · `analyze` (G5/G6/G7) · `paper`
- [Autonomy & routing](#autonomy--routing) — `auto`, `run`
- [Extension](#extension) — `add-recipe`
- [Per-experiment configuration](#per-experiment-configuration) — `consent`, `prolific`,
  `lucid`, `mturk`, `region`, `type`

---

## Bootstrap & install

### `/apsy:setup`

First-run configuration. Picks the Python interpreter (optionally creates a managed venv at
`~/.auto-psynet/venv`), runs the dependency check, offers `/apsy:install` if PsyNet/Dallinger
are missing, asks for `APSY_PROJECT_DIR`, configures the LLM-participant backend
(OpenAI/OpenRouter key, or the ambient Claude), the `{username}.{study}.{host}` server prefix,
AWS credentials, the base domain, and the consent default. The SessionStart hook
(`first-run-nudge`) routes new users here when `~/.auto-psynet/config` doesn't exist.

- **Args:** none — fully interactive.
- **Writes:** `~/.auto-psynet/config`.
- **Run when:** the very first time, or to reconfigure backends/keys/defaults.

### `/apsy:install`

Installs the essential dependencies (PsyNet + Dallinger + optional Python stats stack) in the
active Python environment. Detects venv vs `--user`, shows the install plan via `pip --dry-run`,
asks you to confirm, then installs and records the installed versions to `~/.auto-psynet/config`.
Reruns `/apsy:doctor` to verify.

- **Args:** `--psynet <version>`, `--dallinger <version>`, `--stats` (also install
  pandas/scipy/statsmodels), `--create-venv` (non-interactive managed venv at
  `~/.auto-psynet/venv`), `--python <path>` (point at a specific interpreter).
- **Defaults:** latest stable on PyPI.
- **Run when:** first install, or after switching Python environments.

### `/apsy:update`

Upgrades PsyNet and/or Dallinger to a target version (or latest). Warns if the current project
directory pins a different version. Shows the upgrade plan via `pip --dry-run`, asks to
confirm, runs the upgrade, verifies via `/apsy:doctor`. Hands off to `/apsy:install` if the
packages aren't installed yet.

- **Args:** `--psynet <version|latest>`, `--dallinger <version|latest>`.
- **Run when:** a new PsyNet or Dallinger release ships and you want to pull it in.

---

## Discovery & environment

### `/apsy:help`

Browse the command surface. Reads each `commands/<name>.md`'s `description:` frontmatter for the
listing and prints the full file for the detail view, so the help is always in sync with the
actual commands.

- **Args:** none (list all), `<name>` (detail for one command, e.g. `/apsy:help debug`),
  `--search <query>` (filter by keyword in name or description).
- **Run when:** you want to know what commands exist or what one does.

### `/apsy:status`

Reports where the current experiment stands (reads `<experiment>/.apsy/state.json`) and what
the next action is — which stage, which gates have passed, and which command to run next.

- **Args:** none.
- **Reads:** `<experiment>/.apsy/state.json`.
- **Run when:** resuming work, switching between experiments, or you've forgotten where you
  left off.

### `/apsy:doctor`

Environment diagnostics. Reports the resolved "apsy python" interpreter and its source, checks
that PsyNet + Dallinger import cleanly, hard-checks Redis and PostgreSQL reachability (suggests
`/apsy:services start` on fail), reports `APSY_PROJECT_DIR` writability, the LLM-participant
API key, AWS credentials, and the config file. Read-only unless you approve a fix.

- **Args:** none.
- **Run when:** anything fails unexpectedly; after switching machines/environments; before a
  real deploy.

### `/apsy:project-dir`

Set or inspect `APSY_PROJECT_DIR` — the consistent root where `/apsy:idea` scaffolds new
experiments. Without this set, each `/apsy:idea` creates the experiment in the current working
directory (fine for one-off work, inconsistent across sessions). Optionally symlinks
`~/psynet-data → $APSY_PROJECT_DIR/data` (via `bin/apsy-link-data.sh`, with a 5-case safety
table that refuses if `~/psynet-data` already has content) so PsyNet's hardcoded `assets`,
`launch-data`, and `artifacts` paths route into the project tree.

- **Args:** a path (`/apsy:project-dir ~/research/apsy-experiments`) or none (prompts + reports
  the current value).
- **Writes:** `APSY_PROJECT_DIR` in `~/.auto-psynet/config`.
- **Run when:** initial setup or when reorganizing where experiments live.

### `/apsy:services`

Start / stop / check the runtime services that `psynet debug local` requires: Redis on
`localhost:6379` and PostgreSQL on `localhost:5432` with a `dallinger` superuser and a
`dallinger` database. Idempotent in both directions — safe to run repeatedly. Auto-detects
binaries via `APSY_*_BIN` → `PATH` → common conda paths.

- **Subcommands:**
  - `status` (default) — report ports + running state + dallinger-db existence.
  - `start` — start both; on first start, `initdb`s the pg data dir and creates the
    dallinger user + database. `--redis-only` / `--pg-only` to start one.
  - `stop` — stop cleanly; preserves data on disk.
  - `restart` — stop + start.
- **State dir:** `~/.auto-psynet/services/` (override via `APSY_SERVICES_DIR`).
- **Run when:** before `/apsy:debug` (start), after you're done (stop), or whenever
  `/apsy:debug` reports services unreachable.

---

## Pipeline

The five-stage pipeline with seven gates:

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   idea→plan     experiment code   LLM-pilot · humans     data → findings    paper
                         ╰────────────── iterate ──────────────╯
```

### `/apsy:idea <text>` — FORMULATE (gate G1)

Turn a research idea into a verified, preregistered plan. Picks a short kebab-case `study-slug`
from the idea, creates the experiment directory (under `$APSY_PROJECT_DIR/<study>/` if set,
else `<cwd>/<study>/`), and runs the FORMULATE skills in order: `formulate` (question,
hypotheses, variables) → `literature-ground` (situate + expected effect size) → `design`
(paradigm selection via `config/affinity.yaml`) → `power-analysis` (compute N) →
`analysis-plan` (lock §6 🔒) → `plan-review` (gate **G1**: methodologist + statistician).

- **Args:** the research idea as free text (or nothing → prompts).
- **Writes:** `<experiment>/.apsy/research-plan.md`, `<experiment>/.apsy/state.json`.
- **On G1 PASS:** state advances to `stage: BUILD`. Plan is preregistered (treated as a
  holdout — deviations later are logged, never silent).
- **Run when:** starting a new study from a research question.

### `/apsy:build` — BUILD (gate G2)

Generate the PsyNet experiment from the locked plan. Requires **G1 = pass**. Runs: `scaffold`
(write `experiment.py` + `config.txt` + `requirements.txt`) → `implement-paradigm` (fill
`Trial`/`Node`/`TrialMaker` from `skills/psynet/psynet-function/<paradigm>.md`) →
`generate-stimuli` (only if non-trivial) → `wire-timeline` (consent → instructions →
prescreens → demography → trial maker(s) → debrief) → `test-experiment` (gate **G2**: run
`psynet test local` until green).

- **Args:** none — operates on the current experiment directory.
- **Writes:** `experiment.py`, `config.txt`, `requirements.txt`, stimulus assets if any.
- **On G2 PASS:** state advances to `stage: PILOT`. **Never marked passed without an actual
  green `psynet test local`**.
- **Run when:** after `/apsy:idea` has locked the plan.

### `/apsy:pilot` — PILOT (gate G3)

Run the experiment with LLM-agent participants — no human spend. Drives PsyNet's bot framework
either through `bin/apsy-pilot.sh` (external API: OpenAI/OpenRouter as configured by
`/apsy:setup`) or through the ambient Claude orchestrator. Collects **synthetic** data
(provenance recorded), checks gate **G3** (pipeline runs end-to-end, the preregistered analysis
executes on the synthetic data, the task is doable).

- **Args:** none (uses the configured LLM-participant backend).
- **Requires:** **G2 = pass** + a PsyNet runtime (run `/apsy:doctor` if absent).
- **Writes:** synthetic export with `provenance=synthetic_llm_pilot`.
- **Integrity:** synthetic data is always labeled and never presented as human data.
- **Run when:** after BUILD, before any real-money deploy — de-risk the design.

### `/apsy:debug` — run / stop the experiment

Launch `psynet debug local` in the background so it outlives the Claude session. Thin wrapper
around `bin/apsy-debug.sh`, which:

- Auto-fixes pre-launch state: creates `.gitignore` if missing, runs `git init` + initial
  commit if the dir isn't a git repo, generates `constraints.txt` via `psynet
  generate-constraints` if missing.
- Hard-checks Redis + PostgreSQL reachable (suggests `/apsy:services start` on fail).
- Soft-checks `experiment.py` config (`recruiter="generic"` for local; `dashboard_password`).
- Launches with `nohup`, writes the PID to `<experiment>/.apsy/runtime.pid`, redirects logs to
  `<experiment>/.apsy/runtime.log`.
- Monitors the boot log up to 60 seconds for `Experiment launch complete!`, then reports the
  dashboard URL.

- **Args:** `local` / `--local` (default), `ec2` / `--ec2` (Phase-1 stub for cloud debug),
  `stop` (SIGINT the PID, sweep orphan gunicorn/flask/dallinger workers, remove PID file).
- **Reports:** PID file, log path, dashboard URL (`http://127.0.0.1:5000/dashboard`).
- **Run when:** to drive the experiment yourself in a browser, or to keep it running for
  `/apsy:export`.
- **Not for real recruitment** — that's `/apsy:deploy` (gated by G4).

### `/apsy:export` — export experiment data

Export the running experiment's data while `psynet debug local` is live. Wraps
`bin/apsy-export.sh`. **Run this BEFORE stopping the debug server** — premature `Ctrl+C` may
lose pending DB writes.

- **Args:** forwarded to `psynet export local`. Common ones: `--no-source` (skip the source-code
  zip), `--assets none` (skip media), `--path <dir>` (explicit destination — overrides the
  project-dir redirect).
- **Preflight:** checks `<experiment>/.apsy/runtime.pid` is alive or that port 5000 is
  listening; refuses if not.
- **Output location:**
  - If `APSY_PROJECT_DIR` is set, redirects to `$APSY_PROJECT_DIR/data/<study>/` via `--path`.
  - Else falls through to psynet's default (`~/psynet-data/export/<study>__mode=debug__...`).
- **Bundle:** `anonymous/data/*.csv` (privacy-safe — used by `/apsy:analyze` and bundled into
  the OSF repro package) + `regular/data/...` (with PII — **never share**) + `data.zip` +
  `source_code.zip`.
- **Common failure: `KeyError: dashboard_password`** → add `dashboard_password` to
  `Exp.config` and restart `/apsy:debug` (the four experiment templates already include this;
  hand-written `experiment.py` typically doesn't).

### `/apsy:deploy` — DEPLOY & RECRUIT (gate G4)

Deploy for **real human** data collection and recruit. **G4 is a HARD gate at every autonomy
level** — never auto-passed. Requires:
- Explicit human approval in the chat.
- A Cornell IRB approval / exemption attestation (numbered, dated).
- A configured spend cap (`spend.cap_usd`).
- Green G2 + G3.

After deploy, `apsy:recruit` launches the recruiter (Prolific / Lucid / MTurk, configured per
experiment via `/apsy:prolific` etc.) within the spend cap and monitors live data quality.
Stops when the clean target N is met or the cap is approached.

- **Requires:** **G2 + G3 = pass**, plus the four G4 conditions above.
- **Reads ethics policy:** [`config/ethics-policy.md`](config/ethics-policy.md) §1.2, §3.
- **Run when:** the design is verified on synthetic data and you have IRB + budget approval.

### `/apsy:analyze` — ANALYZE (gates G5/G6/G7)

Run the preregistered analysis on exported data. Operates on already-exported data — use
`/apsy:export` first; this command does NOT trigger the export.

- **Stages:**
  1. `apsy:export-data` — load the export (auto-detects most-recent in `data/`).
  2. `apsy:data-quality` — gate **G5**: completion, the preregistered exclusions,
     duplicates, target-N → clean dataset.
  3. `apsy:analyze` — write + execute the **LOCKED §6** analysis (real stats from
     scipy/statsmodels); effects + CIs + figures.
  4. `apsy:interpret` — gate **G6**: verify analysis-matched-preregistration; report effect
     + CI; is H1 supported?
  5. `apsy:iterate` — gate **G7**: ship → `/apsy:paper`, or iterate → loop back to BUILD/PILOT.
- **Args:** none (operates on the current experiment).
- **Writes:** `<experiment>/.apsy/analysis/results.json`, figures, decisions log.
- **Integrity:** numbers come **only** from executed analyses; deviations from the locked plan
  are logged, never silent. Synthetic results are labeled in-silico.

### `/apsy:paper` — PUBLISH

Assemble the paper draft + OSF-ready reproducibility package. Best after gate **G7 = ship**,
but can also draft from current findings.

- **Stages:**
  1. `apsy:write-paper` — assemble the draft from `.apsy/research-plan.md`, `experiment.py`,
     `.apsy/analysis/results.json` + figures, `.apsy/decisions.md`.
  2. `apsy:repro-package` — bundle code + locked preregistration + analysis + **anonymized**
     data via `bin/apsy-repro.sh`.
- **Methods** come from the actual pipeline; **Results** come **only** from the executed
  analysis (`results.json`) — never invented. Synthetic / LLM-pilot data is labeled
  in-silico, and an **AI-involvement disclosure** is included.

---

## Autonomy & routing

### `/apsy:auto [text]`

Smart router. Turns a free-text intent into the right `/apsy:*` command. Routing is
**deterministic** via `bin/apsy-route.py` + `config/routing.json` (no LLM scoring of intents).
The current `.apsy/state.json` stage gets a small score boost so "what's next?" routes to the
right next step.

- **Confidence policy:**
  - HIGH → auto-dispatch.
  - MEDIUM → confirm the top-2 via `AskUserQuestion`.
  - LOW → show the menu (organized by pipeline stage), ask the user.
- **Run when:** you don't remember the exact command name.

### `/apsy:run [text|--resume]`

Autonomous research pipeline — idea → paper. Walks the full lifecycle honoring
`autonomy_level` from `.apsy/state.json`.

- **Autonomy levels:**
  - `supervised` (default) — pause for the user at every gate.
  - `semi_autonomous` — auto-advance soft gates (G1, G2, G3, G5, G6); pause at **G4**
    (always) and G7.
  - `autonomous` — auto soft + G7; **G4 ALWAYS PAUSES** (real money, real people).
- **Args:** a research idea, or `--resume` to continue an existing experiment. Add
  `--with-deployment` to include the real-human branch (G4 still hard-blocks until approval +
  IRB + spend cap).
- **Resumable:** re-running `/apsy:run` picks up from `state.json`'s current stage.
- **Default mode:** synthetic-only — FORMULATE → BUILD → LLM-PILOT → synthetic ANALYZE →
  PUBLISH (all in-silico, labeled).

---

## Extension

### `/apsy:add-recipe`

Add a new file under `skills/psynet/psynet-function/` (a paradigm or cross-cutting capability)
and auto-update the parent index in `skills/psynet/SKILL.md`. Use this when teaching
Auto-PsyNet about a paradigm it doesn't know yet — a new `TrialMaker` subclass, a new
prescreen, a new asset workflow.

- **Args:** `--name <slug>`, `--category {paradigm|cross-cutting}`, `--trial-maker <Class>`,
  `--purpose "<one line>"`. With no args, prompts for everything.
- **Writes:** `skills/psynet/psynet-function/<name>.md`, updates the index in
  `skills/psynet/SKILL.md`.
- **Run when:** extending the PsyNet knowledge pack.

---

## Per-experiment configuration

These commands write to `<experiment>/.apsy/state.json` (via `bin/apsy-state.sh`), so each
experiment carries its own recruitment and deployment settings.

### `/apsy:consent`

Override the default consent (PsyNet `MainConsent`) with a custom one. Asks: separate file
path? class/function to import? how to use it (e.g. `consent_x(DURATION=.., PAYMENT=..)`,
first in the timeline)? Records the answers under `consent` in the experiment's `state.json`;
`apsy:wire-timeline` reads them at build time. Point at your institution's IRB-approved
consent module (typically a `(Module, Consent)` subclass).

### `/apsy:prolific`

Configure Prolific recruitment. Records `recruitment.platform = prolific`, `base_payment`,
**`wage_per_hour` (≥ the $10 ethics floor, §1.3)**, `prolific_estimated_completion_minutes`,
and a qualifications JSON. These flow into `experiment.py`'s `get_prolific_settings()` at
build.

### `/apsy:lucid`

Configure Lucid/Cint recruitment — global/representative panels, useful for cross-cultural
studies. Records `recruitment.platform = lucid`, locale/target group, completion estimate,
payment, with `wage_per_hour ≥ $10`. See PsyNet's `psynet lucid` tooling for cost/locale
management.

### `/apsy:mturk`

Configure Amazon Mechanical Turk recruitment. Records `recruitment.platform = mturk`,
`base_payment`, `wage_per_hour` (≥ floor), qualification requirements, HIT settings.

### `/apsy:region`

Override the default AWS region for EC2 provisioning (default `us-east-1`). Writes
`APSY_AWS_REGION` in `~/.auto-psynet/config`.

### `/apsy:type`

Override the default EC2 instance type for provisioning. Default is auto-sized
**`m7i.{N}xlarge`** by estimated experiment size — `xlarge` = 16 GB, `2xlarge` = 32 GB,
`4xlarge` = 64 GB, …. Writes `APSY_EC2_TYPE` in `~/.auto-psynet/config`.

---

## See also

- [`README.md`](README.md) — install + quick start.
- [`project-plan/04-skills-agents-commands.md`](project-plan/04-skills-agents-commands.md)
  §4.3 — the design-doc command catalog with priorities (P0/P1/P2) and skill mapping.
- [`config/gates/`](config/gates/) — full rubrics for G1–G7.
- [`config/ethics-policy.md`](config/ethics-policy.md) — the integrity policy (synthetic data
  labeling, G4 hard gate, wage floor, AI-involvement disclosure).
- [`config/routing.json`](config/routing.json) — the keyword routing table used by
  `/apsy:auto`.
- For the live, in-CLI version of this catalog: `/apsy:help` (no args) or
  `/apsy:help <name>`.
