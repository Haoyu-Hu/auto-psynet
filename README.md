# Auto-PsyNet (`apsy`)

A Claude Code plugin that automates the lifecycle of online **behavioral experiments** built on
[PsyNet](https://psynetdev.gitlab.io/PsyNet/): a raw research idea → a verified, preregistered plan →
working PsyNet experiment code → **LLM-pilot** and human deployment → analysis & iteration → a
publication-ready paper. Experimental subjects can be **humans and/or LLM agents**.

> **Status: Phase 0 (foundations / scaffolding).** The plugin skeleton, manifest, operating policy, and
> command surface are in place; skills and paradigm recipes are filled in per the roadmap. See
> [`project-plan/`](project-plan/) for the full design and [`project-plan/05-roadmap.md`](project-plan/05-roadmap.md)
> for build order.

## Pipeline

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   idea→plan     experiment code   LLM-pilot → humans      data → findings    paper
                         ╰────────────── iterate ──────────────╯
```

## Command surface

| Command | Purpose |
|---------|---------|
| `/apsy:setup` | First-run config: LLM-participant backend (OpenAI/OpenRouter or ambient Claude), username/server prefix, AWS creds, base domain |
| `/apsy:doctor` | Environment diagnostics — essential deps (`psynet`/`dallinger`), Docker/Postgres/Redis, keys, AWS, config |
| `/apsy:status` | Where the current experiment stands (reads `.apsy/state.json`) |
| `/apsy:debug` | Run an experiment locally or on a provisioned EC2 instance |
| `/apsy:idea` | Start FORMULATE — idea → verified plan *(Phase 1)* |
| `/apsy:build` | Generate the PsyNet experiment *(Phase 1)* |
| `/apsy:pilot` | Run the experiment with LLM-agent participants *(Phase 1)* |
| `/apsy:analyze` | Export + run the preregistered analysis *(Phase 1)* |

Plus configuration commands: `apsy:consent`, `apsy:prolific` / `apsy:lucid` / `apsy:mturk`,
`apsy:region`, `apsy:type`.

## Install (development)

```bash
# from a Claude Code session, with this repo checked out:
/plugin marketplace add /work/hdd/bgmm/hhu4/auto-psynet
/plugin install apsy@auto-psynet
/apsy:setup
```

## Layout

```
.claude-plugin/   plugin + marketplace manifests (name locked to "apsy")
commands/         slash commands
skills/           SKILL.md execution contracts
agents/           expert personas + routing (config.yaml)
hooks/            lifecycle + safety hooks
bin/              the deterministic engine (psynet/analysis/LLM-participant wrappers)
config/           ethics-policy, gates, pipeline, paradigm recipes, domain priors, affinity, templates
tests/            assembly + behavior tests
project-plan/     the full design (read this first)
materials/        local reference clones (PsyNet, Dallinger) — dev-only, gitignored, not shipped
experiment-examples/  real PsyNet experiments for dev reference — dev-only, gitignored, not shipped
```

Built on [PsyNet](https://gitlab.com/PsyNetDev/PsyNet) / [Dallinger](https://github.com/Dallinger/Dallinger).
Ethics & integrity policy: [`config/ethics-policy.md`](config/ethics-policy.md).
