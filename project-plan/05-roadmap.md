# 05 — Roadmap, Risks & Open Decisions

## 5.1 Build order

Sequenced to de-risk the two hardest problems first — **verifying the plan** and **generating a PsyNet
experiment that actually runs** — before touching real money, real people, or breadth.

**Two tracks after the MVP.** All four PsyNet differentiators (chains, network/multiplayer,
cross-cultural/multilingual, human-AI hybrid) are headline capabilities, prioritized early. Because
**LLM-piloting develops any paradigm on synthetic data with no spend and no public host**, paradigm and
capability work (**Track A**, Phases 2–3) can proceed in the current environment regardless of the
hosting decision (D1). Real human deployment (**Track B**, Phase 4) is a parallel track slotted in
whenever D1 + a budget + a chosen study are ready — it is *not* gated behind finishing all of Track A.

### Phase 0 — Foundations & environment  *(prerequisite — substantially complete)*
Stand up the skeleton and prove the lab works.
- ✅ Plugin manifest (`.claude-plugin/`, `name:"apsy"` LOCKED), directory layout, `CLAUDE.md` operating
  policies, `tests/validate-assembly` smoke test green.
- ✅ The **engine** (`bin/apsy-*`): `apsy-common.sh` (interpreter resolver), `apsy-config.sh`,
  `apsy-install.sh` / `apsy-update.sh` paths (single engine, `--upgrade` flag), `apsy-check.sh`
  (dep + version check), `apsy-doctor.sh`, `apsy-debug.sh`, `apsy-deploy.sh`, `apsy-recruit.sh`,
  `apsy-state.sh`, `apsy-route.py`, `apsy-run.py`, `apsy-power.py`, `apsy-data-quality.py`,
  `apsy-repro.sh`, `apsy-add-recipe.py` — all wrapping the real `psynet` CLI / pip / analysis stack.
- ✅ `.apsy/` state templates + `state.json` schema; `/apsy:status`.
- ✅ **`/apsy:setup`** — first-run config + dep check; **tied as the start of the plugin** via the
  `first-run-nudge` SessionStart hook (nudges `/apsy:setup` when `~/.auto-psynet/config` is absent).
- ✅ **`/apsy:install`** — auto-install psynet + dallinger + stats stack with version pinning; **owns
  the interpreter decision** — auto-detects venv/`APSY_PYTHON`; offers managed venv at
  `~/.auto-psynet/venv` (`--create-venv`); accepts opt-out via `--python PATH` for conda/poetry/uv.
- ✅ **`/apsy:update`** — upgrade psynet/dallinger to specified or latest; reuses the install engine
  via `--upgrade`; prints `old → new` diff; warns on project-pin desync.
- ✅ **`/apsy:doctor`** — validates the resolved "apsy python" + delegated dep check (`apsy-check`),
  plus Docker/Postgres/Redis, LLM key (or fallback), AWS creds, base domain, config.
- ✅ **`/apsy:add-recipe`** — extension command: add a new file under `skills/psynet/psynet-function/`
  (paradigm or cross-cutting) and auto-insert a row in the parent index table.
- ✅ **`debug` target selector** — `local` (`psynet debug local`) and `ec2` (Dallinger provisioning)
  backends wired into `apsy-debug.sh` (resolves D1).
- **Exit criterion (met for plugin-side foundations):** the plugin loads, `apsy:setup` / `apsy:install`
  / `apsy:doctor` / `apsy:status` work, assembly is green, the interpreter resolver + managed-venv
  path are operational. **Remaining external dependency for "hello-world on ec2":** an AWS account
  with the configured base domain — the only Phase 0 item that can't be exercised on this dev box.

### Phase 1 — The core loop on synthetic data (MVP)
FORMULATE → BUILD → LLM-PILOT → synthetic ANALYZE, supervised, local, **static-trials paradigm only**.
- Personas: `methodologist`, `statistician`, `psynet-engineer`.
- Skills: the MVP set in [`04-skills-agents-commands.md`](04-skills-agents-commands.md §4.7).
- The **LLM-participant driver** (engine) — the flagship piece; budget real time here.
- Gates G1–G3 + G6; `psynet-lint` + `spend-gate` + `load-experiment-context` hooks.
- **Exit criterion (north-star MVP demo):** `/apsy:idea "<a static-trial idea>"` →
  preregistered plan that passes G1 → generated experiment that passes `psynet test local` (G2) →
  LLM-pilot run producing synthetic data (G3) → the preregistered analysis executes on that data and
  `interpret` reports effects (G6) — all artifacts in `.apsy/`, all decisions logged. No human, no spend.

### Phase 2 — Differentiating paradigms (the novelty engine) · *Track A*
Build out the headline paradigms on LLM-pilot/synthetic data — **no spend, no public host needed** — so
this proceeds in the current environment regardless of D1. `literature-ground` + `generate-stimuli`
enrich FORMULATE/BUILD here too.
- **GSP / MCMCP** (`GibbsTrialMaker` + media/audio variants, `MCMCPTrialMaker`) — the **flagship**:
  representation-recovery sampling, the canonical match for the perception/music anchor. A full GSP study
  (ideally on a perceptual/auditory dimension — PsyNet's sweet spot) end-to-end on synthetic data.
- **Transmission chains** (`ImitationChainTrialMaker`) — `create_initial_seed`, `summarize_trials`,
  within/across chains; iterated-learning studies (language/culture/memory).
- **Network / real-time multiplayer** (`GraphChainTrialMaker` + `SyncGroups`) — interacting-participant
  networks; the infrastructure real-time hybrid builds on.
- Each ships a complete `skills/psynet/psynet-function/` recipe (with its affinity metadata) + an
  LLM-piloted end-to-end run + analysis.
- **Exit criterion:** at least the flagship **GSP** paradigm **and** the network paradigm run end-to-end
  (build → LLM pilot → analysis) on synthetic data, with recipes documented.

### Phase 3 — Global + human-AI hybrid · *Track A*
The two cross-cutting differentiators, layered on Phase 2.
- **Multilingual / global:** the `localize` skill (`psynet translate`), locale handling, **measurement
  invariance** as a G6 check, and global-recruiter (Lucid) config prepared for Track B.
- **Human-AI hybrid:** async hybrid first (alternating human↔AI chains via the LLM-participant harness),
  then real-time sync hybrid (humans + LLM agents in one `SyncGroups` network); mixed-sample analysis.
- **Exit criterion:** a multilingual experiment translated + invariance-checked on synthetic data, and a
  hybrid human-AI chain or network piloted end-to-end.

### Phase 4 — Real human studies · *Track B (slotted when D1 + budget + a study are ready)*
Turn any completed pipeline outward to real participants. **Not gated behind all of Track A** — it can
start once Phase 1 + one paradigm + a host exist; it *is* gated behind D1 (public hosting).
- Skills: `deploy`, `recruit`, `data-quality`, `iterate`; persona `data-analyst`.
- Deployment adapter `ssh`/`heroku`; Prolific (or Lucid for global) integration; live monitoring.
- **Hard gate G4** fully enforced (approval token + spend cap); G5 data-quality; G7 iterate/ship.
- **Exit criterion:** a real, budget-capped study run end-to-end, analyzed, with one recorded iteration.

### Phase 5 — Publish
- `write-paper`, `repro-package`; `science-writer` + `literature-scholar` personas.
- **Exit criterion:** a paper draft + OSF-ready package from a completed study, Methods faithfully
  derived from the actual pipeline and Results from the actual analysis.

### Phase 6 — Autonomy, multi-LLM review, integrations
- `/apsy:auto` smart router; `/apsy:run` autonomous pipeline; `semi_autonomous`/`autonomous` levels.
- `adversarial-reviewer` + optional **multi-LLM** review of designs/stats (the kickoff's deferred option).
- Optional **MCP server**; cross-experiment `recall` (file-based); human-vs-LLM comparison
  templates; remaining paradigms (staircase, dense, create-and-rate); domain-priors expansion.

## 5.2 Milestones (checkpointable)

| M | Milestone | Phase |
|---|-----------|-------|
| M0 | `doctor` green + `psynet debug local` runs hello-world | 0 — *infra-dependent (Docker or EC2 access)* |
| M1 | Plugin loads in Claude Code; `/apsy:status` + assembly test pass | 0 — ✅ **met** (assembly green; 30 skills · 21 commands · 4 hooks shipped on `main`) |
| M2 | FORMULATE produces a plan that passes G1 on a sample idea | 1 |
| M3 | BUILD generates a static-trial experiment that passes `psynet test local` (G2) | 1 |
| M4 | LLM-participant driver completes a pilot run; synthetic data exported (G3) | 1 |
| M5 | Preregistered analysis runs on pilot data; `interpret` reports effects (G6) — **MVP done** | 1 |
| M6 | **Flagship GSP** study (perception/audio) end-to-end (build → LLM pilot → analysis) on synthetic data | 2 (A) |
| M7 | **Network / `SyncGroups`** paradigm end-to-end on synthetic data | 2 (A) |
| M8 | **Multilingual** experiment translated + **measurement-invariance** checked on synthetic data | 3 (A) |
| M9 | **Human-AI hybrid** chain/network piloted end-to-end | 3 (A) |
| M10 | Real budget-capped study deployed under G4, analyzed, one improvement iteration recorded | 4 (B) |
| M11 | Paper draft + repro package from a completed study | 5 |

## 5.3 Risks & mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **PsyNet runtime on HPC (Delta):** Docker may be unavailable; no inbound public networking. | Med (was High) | **Mitigated by the `ec2` backend** (Dallinger provisioning) for any server-side work; `doctor` detects local Docker + AWS creds and routes. Local + LLM-pilot need no public endpoint, so the MVP is insulated; Track B uses EC2 (or an existing host). |
| **PsyNet code generation is hard** (custom subclasses, async, the 8 gotchas). | **High** | Ground in execution (`psynet test local` is the gate, not the LLM's confidence); `psynet-lint` hook; start with the single cleanest paradigm (static); curate few-shot exemplars from `demos/`. |
| **LLM-participant fidelity / cost.** | Med | Keep pilot N small + capped; validate the driver against deterministic bots first; label synthetic data; never present it as human. |
| **Four headline differentiators = ambitious scope.** | Med | LLM-piloting lets all of Track A develop on synthetic data with no spend/host, so ambition ≠ blocked-on-infra; still build incrementally (one recipe at a time) and keep the static MVP as the proof-of-loop gate before Track A. |
| **Real-time synchronization (`SyncGroups`) complexity** — multiplayer timing, dropouts, hybrid human-AI turn-taking. | Med–High | Do async hybrid first; add deterministic bots to sync tests; lean on PsyNet's existing sync infra + `docs/tutorials/synchronization.rst`; treat real-time sync hybrid as the last Track-A item. |
| **Scientific validity of LLM-as-subject claims.** | Med | Honesty guardrails (scope §1.5); Level-2 outputs flagged in-silico with caveats; comparison studies framed carefully. |
| **p-hacking / HARKing via the automation itself.** | **High** | Preregistration lock at G1 (treated as a holdout); G6 checks analysis-matched-plan; deviations logged, never silent. |
| **Real-money / real-people harm.** | **High** | G4 hard gate (never auto-passed); spend caps as PreToolUse blocks; human owns ethics/IRB. |
| **External memory service.** | n/a | **Not used** — memory is file-based only (`.apsy/` + native Claude Code memory); no external memory dependency. |
| **Scope creep toward octopus's size.** | Med | Strict P0/P1/P2 discipline; MVP = one paradigm, synthetic-only, supervised, local. |
| **PsyNet/Dallinger version churn.** | Low–Med | Pin `psynet==` in generated `requirements.txt`; engine asserts the version `doctor` validated. |

## 5.4 Decisions — resolved & still open

| # | Decision | Why it matters | Resolution / default |
|---|----------|----------------|----------------------|
| D1 | ✅ **Resolved** — runtime host for PsyNet's stack. | Was the Phase-0 blocker. | **EC2 via Dallinger provisioning** is the primary server path (Docker + public web for cloud-debug *and* deploy; sidesteps HPC limits); **local debug** where a Docker box exists, else EC2-first. `debug` picks the target. Residual: confirm AWS creds + base domain (D10) at `setup`. |
| D2 | ✅ **Resolved** — plugin name + namespace. | Locked early; appears everywhere. | Call name **`apsy`** (`/apsy:*`), repo **`auto-psynet`**. |
| D3 | ✅ **Resolved** — stats stack. | Analysis runner + power tooling. | **Python-first** (`pandas`/`scipy`/`statsmodels`/`pingouin`); add R (`pwr`/`lme4`/`simr`) when a design needs it. |
| D4 | ✅ **Resolved** — recruitment platform. | Drives `recruit` + `config.txt` + spend model. | **Prolific by default**, with **Lucid** (global panels) and **MTurk** also supported. |
| D5 | ✅ **Resolved** — LLM-participant model + cap. | Cost + fidelity of piloting. | **Model = whatever `setup` configured** (the OpenAI/OpenRouter model, or ambient Claude). Keep a small default N + hard per-pilot $ cap in `state.json`. |
| D6 | ✅ **Resolved** — literature sources for `literature-ground`. | Auth + coverage. | **Web search + arXiv** by default (open); **Semantic Scholar API** additionally when its key is detected. |
| D7 | ✅ **Resolved** — scientific-integrity & ethics policy. | The G1 ethics check + the G4 human-deploy gate. | Codified in [`../config/ethics-policy.md`](../config/ethics-policy.md): consent default `MainConsent` (override `apsy:consent`); wage floor **$10/hr**; **hard-block** for consent / underpayment / deception-without-debrief / vulnerable-populations + fabrication / LLM-honesty / AI-disclosure; **IRB attestation required** before real deployment; **AI-involvement disclosure required**. |
| D10 | ✅ **Resolved** — AWS defaults for EC2 (`{username}.{study}.{host}`). | `ec2` provisioning + DNS. | Region **`us-east-1`** (override `apsy:region`); instance **`m7i.{N}xlarge`** auto-sized by estimated experiment size — `xlarge`=16 GB, `2xlarge`=32 GB, `4xlarge`=64 GB, … (override `apsy:type`). Base **domain** still captured at `setup` (needs one you control). |

> **Status: all kickoff + follow-up decisions (D1–D10) are resolved.** What remains is execution — the
> only external dependency before Phase 0 is provisioning infra (AWS account/region + a base domain;
> optionally a local Docker box). The ethics policy is codified in [`../config/ethics-policy.md`](../config/ethics-policy.md).
| D8 | ✅ **Resolved** — seed domains for `config/domains/`. | Initial Domain Design-Priors layer. | **Perception & psychophysics · music & audio cognition · language & communication · memory/learning/decision-making** (expand on demand). |
| D9 | ✅ **Resolved** — flagship paradigm (coupled to D8 via the affinity matrix). | First differentiator demo after the static MVP. | **GSP (`GibbsTrialMaker`)**, anchored on perception/mental-representations; MCMCP close second; transmission chains follow. |

## 5.5 Immediate next actions (once this plan is approved)

1. **Provision infra** — confirm an AWS account/region + a base domain you control for EC2 naming, and
   (optionally) a local Docker-capable machine (else EC2-first). All decisions D1–D10 are resolved; this
   is the only remaining external dependency before Phase 0.
2. Scaffold the plugin repo: `.claude-plugin/` manifest (lock `apsy`), directory layout, `CLAUDE.md`,
   assembly test. (Borrow octopus's manifest + hook-wiring shapes.)
3. Build `/apsy:setup` + `/apsy:doctor` and get a hello-world running via `debug` (local `psynet debug
   local`, or a provisioned `ec2` instance) — M0.
4. Author the three P0 personas and the FORMULATE skills; reach M2 (a plan passing G1) on a sample idea.
5. Tackle BUILD + the LLM-participant driver toward the MVP demo (M3–M5).
6. The `skills/psynet/` knowledge pack (the `apsy:psynet` index + `psynet-function/` recipes for all 8
   paradigms + cross-cutting functions) is built; `config/domains/` is seeded (perception; others stub) —
   so Track A can begin the moment the MVP loop closes.

> This plan is intentionally staged so that the first demonstrable, useful result (M5: idea → verified
> plan → working experiment → piloted synthetic results) requires **no real participants, no public
> hosting, and no spend** — making it achievable in the current environment while proving the riskiest
> parts of the system.
