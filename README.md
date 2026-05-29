# Auto-PsyNet (`apsy`)

A Claude Code plugin that automates the lifecycle of online **behavioral experiments** built on
[PsyNet](https://psynetdev.gitlab.io/PsyNet/): from a raw research idea → preregistered plan →
working PsyNet code → LLM-piloted (and human) deployment → analysis → publication-ready paper.
Subjects can be **humans, LLM agents, or both**.

## Install

```bash
# From a Claude Code session, with this repo checked out:
/plugin marketplace add /path/to/auto-psynet
/plugin install apsy@auto-psynet

# Then, inside Claude Code:
/apsy:setup           # one-time config (interpreter, project-dir, LLM backend, AWS, ...)
/apsy:install         # install psynet + dallinger (offers a managed venv)
/apsy:doctor          # verify the runtime
```

## Quick start — a new study

```bash
/apsy:idea "<your research question>"   # → preregistered plan (gate G1)
/apsy:build                              # → working PsyNet code (gate G2)

/apsy:services start                     # Redis + Postgres for local debug
/apsy:debug                              # launch psynet debug local
/apsy:export                             # export data while it runs
/apsy:debug stop                         # clean shutdown
/apsy:services stop

/apsy:pilot                              # LLM-agent participants (gate G3)
/apsy:analyze                            # preregistered analysis (gates G5/G6/G7)
/apsy:paper                              # paper draft + OSF reproducibility package
```

For real human deployment, `/apsy:deploy` triggers gate **G4** — explicit human approval + IRB
attestation + a spend cap required at every autonomy level (see
[`config/ethics-policy.md`](config/ethics-policy.md)).

## Browsing the command surface

```bash
/apsy:help                  # list every command + a one-line description
/apsy:help <name>           # detailed help for one command (e.g. /apsy:help debug)
/apsy:help --search redis   # filter by keyword
```

Or use `/apsy:auto "<free-text intent>"` to let the smart router pick the right command for you.

## Pipeline

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   idea→plan     experiment code    LLM-pilot · humans     data → findings    paper
                         ╰────────────── iterate ──────────────╯
```

Seven quality gates (G1-G7) gate transitions; rubrics live in [`config/gates/`](config/gates/).
`/apsy:run` walks the whole pipeline autonomously (honoring `autonomy_level`; G4 is always hard).

## Project organization

Set `APSY_PROJECT_DIR` once (via `/apsy:setup` or `/apsy:project-dir`) and every new study gets a
consistent home; exports + PsyNet's hardcoded data paths are routed into it:

```
$APSY_PROJECT_DIR/
├── pleasantness-rating/          ← per-experiment dir
│   ├── experiment.py  config.txt  requirements.txt  constraints.txt
│   └── .apsy/                    ← state + reports + paper draft
├── color-gsp/
└── data/                         ← (optional ~/psynet-data symlink)
    ├── export/<study>/           ← exports land here
    └── assets/  launch-data/     ← PsyNet's other hardcoded dirs
```

Without `APSY_PROJECT_DIR`, experiments scaffold in the current working directory — fine for
one-off work, less convenient across sessions.

## Optional: MCP server

For non-Claude clients (Cursor, Codex, custom automation), an opt-in MCP server exposes six engine
tools (`apsy_status`, `apsy_doctor`, `apsy_route`, `apsy_next`, `apsy_power`, `apsy_data_quality`).
See [`mcp-server/README.md`](mcp-server/README.md). Off by default — set `APSY_MCP_ENABLED=true` to
enable.

## Status

The end-to-end runtime arc is verified on synthetic data with real psynet 13.2 / dallinger 12.2
runs. Phase 4 (real human studies) is infra-blocked on AWS + base domain; everything else is
exercised. See [`project-plan/`](project-plan/) for the design rationale and roadmap.

Built on [PsyNet](https://gitlab.com/PsyNetDev/PsyNet) /
[Dallinger](https://github.com/Dallinger/Dallinger). Ethics & integrity policy:
[`config/ethics-policy.md`](config/ethics-policy.md).
