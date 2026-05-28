# Auto-PsyNet (`apsy`)

A Claude Code plugin that automates the lifecycle of online **behavioral experiments** built on
[PsyNet](https://psynetdev.gitlab.io/PsyNet/): a raw research idea → a verified, preregistered plan →
working PsyNet experiment code → **LLM-pilot** and human deployment → analysis & iteration → a
publication-ready paper. Experimental subjects can be **humans and/or LLM agents**.

> **Status: Phase 0 (foundations).** The plugin skeleton, manifest, operating policy, command surface,
> the deterministic engine, the LLM-participant driver, the 5-stage pipeline state machine, the PsyNet
> knowledge pack (8 paradigm recipes + 8 cross-cutting), and the analysis stack are all in place.
> Skills and paradigm recipes continue to be filled in per [`project-plan/05-roadmap.md`](project-plan/05-roadmap.md);
> see [`project-plan/`](project-plan/) for the full design.

## Pipeline

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   idea→plan     experiment code   LLM-pilot → humans      data → findings    paper
                         ╰────────────── iterate ──────────────╯
```

`/apsy:run` walks the whole pipeline autonomously (honoring `autonomy_level`; **G4 is HARD** at every
level — real human deploy always requires explicit human approval + IRB attestation + spend cap).
`/apsy:auto` is a smart router that turns a free-text intent into the right `/apsy:*` command.

## Command surface

### Setup & maintenance

| Command | Purpose |
|---------|---------|
| `/apsy:setup` | First-run config — LLM-participant backend (OpenAI/OpenRouter or ambient Claude), username/server prefix, AWS creds, base domain, consent default. |
| `/apsy:install` | Auto-install the essential deps (`psynet` + `dallinger` + optional Python stats stack) with optional version pinning. |
| `/apsy:update` | Upgrade PsyNet / Dallinger to a specified or the latest version in the active Python env. |
| `/apsy:doctor` | Environment diagnostics — essential deps, Docker/Postgres/Redis, LLM keys, AWS, config. |
| `/apsy:status` | Where the current experiment stands (reads `<experiment>/.apsy/state.json`) + the next action. |

### Pipeline (one command per stage)

| Command | Stage | Purpose |
|---------|-------|---------|
| `/apsy:idea` | FORMULATE | Idea → verified, preregistered plan (gate G1). |
| `/apsy:build` | BUILD | Generate the PsyNet experiment from the locked plan; scaffold + implement + bot-test to G2. |
| `/apsy:pilot` | PILOT | Run the experiment with LLM-agent participants — validate pipeline + analysis on synthetic data (gate G3). No human spend. |
| `/apsy:debug` | — | Run the experiment for debugging — local (`psynet debug local`) or on a provisioned EC2 instance. |
| `/apsy:deploy` | DEPLOY | Deploy for **real human** data (gate G4) + recruit. HARD gate at every autonomy level. |
| `/apsy:analyze` | ANALYZE | Export data, run the preregistered analysis, report effects; iterate or ship (gates G5/G6/G7). |
| `/apsy:paper` | PUBLISH | Assemble the paper draft (Methods from pipeline, Results from analysis) + an OSF-ready reproducibility package. |

### Autonomy & routing

| Command | Purpose |
|---------|---------|
| `/apsy:run` | Autonomous pipeline — idea → paper. Honors `autonomy_level`; **G4 always HARD**. |
| `/apsy:auto` | Smart router — natural-language intent → the right `/apsy:*` command (rule-based, stage-aware). |

### Extension

| Command | Purpose |
|---------|---------|
| `/apsy:add-recipe` | Add a new file under `skills/psynet/psynet-function/` (a new paradigm or cross-cutting capability) and auto-update the parent index. |

### Per-experiment configuration

| Command | Purpose |
|---------|---------|
| `/apsy:consent` | Configure the consent form (default: PsyNet `MainConsent`). |
| `/apsy:prolific` · `/apsy:lucid` · `/apsy:mturk` | Configure the recruiter for this experiment. |
| `/apsy:region` · `/apsy:type` | Override AWS region (default `us-east-1`) / EC2 instance type (default auto-sized `m7i.{N}xlarge`). |

## Install (development)

```bash
# from a Claude Code session, with this repo checked out:
/plugin marketplace add /work/hdd/bgmm/hhu4/auto-psynet
/plugin install apsy@auto-psynet

# inside Claude Code:
/apsy:setup        # first-run config (LLM backend, username, AWS, base domain)
/apsy:install      # install psynet + dallinger into the active Python env
/apsy:doctor       # verify the runtime
```

> **Recommended: run inside a Python virtual environment.** PsyNet pulls a large dependency tree
> (Dallinger, Postgres bindings, Selenium, ...) — keep it isolated:
> ```bash
> python3 -m venv ~/apsy-env && source ~/apsy-env/bin/activate
> ```
> The `/apsy:install` engine auto-detects an active venv and installs there. Without a venv it falls
> back to `--user` when site-packages aren't writable. It **never** silently passes
> `--break-system-packages`.

## Optional: MCP server

For non-Claude clients (Cursor, Codex, custom automation), a thin opt-in MCP server exposes six
engine tools — `apsy_status`, `apsy_doctor`, `apsy_route`, `apsy_next`, `apsy_power`,
`apsy_data_quality`. See [`mcp-server/README.md`](mcp-server/README.md). The server is stdlib-only
Python and is **off by default** (`APSY_MCP_ENABLED=true` to enable).

## Layout

```
.claude-plugin/   plugin + marketplace manifests (name locked to "apsy")
commands/         slash commands (21)
skills/           SKILL.md execution contracts (30) — incl. skills/psynet/ knowledge hub
agents/           expert personas + routing (config.yaml) — 9 personas
hooks/            lifecycle + safety hooks
bin/              the deterministic engine (psynet / analysis / LLM-participant wrappers)
config/           ethics-policy, gates, pipeline, affinity, domain priors, templates
mcp-server/       optional stdlib MCP server (off by default)
tests/            assembly + behavior tests
project-plan/     the full design (read this first)
materials/        local reference clones (PsyNet, Dallinger) — dev-only, gitignored, not shipped
experiment-examples/  real PsyNet experiments for dev reference — dev-only, gitignored, not shipped
```

Built on [PsyNet](https://gitlab.com/PsyNetDev/PsyNet) / [Dallinger](https://github.com/Dallinger/Dallinger).
Ethics & integrity policy: [`config/ethics-policy.md`](config/ethics-policy.md).
