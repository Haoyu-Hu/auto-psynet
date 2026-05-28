---
name: setup
description: "Configure Auto-PsyNet — use on first run or when the user says 'apsy setup', 'configure apsy', or has no ~/.auto-psynet/config. Sets the LLM-participant backend, username/server prefix, AWS/EC2 + base domain, and notes the consent default."
---

# apsy:setup — first-run configuration

> EXECUTION CONTRACT. Numbered steps; do not skip. Writes user-level config to `~/.auto-psynet/config`
> (KEY=VALUE). Never store raw API keys in the repo — reference env vars.

## STEP 1 — Resolve config
Run `bin/apsy-common.sh` to ensure `~/.auto-psynet/` exists and load any existing config. If a config
already exists, show it and ask whether to reconfigure or edit a single field. **Do not proceed until
the config location is confirmed.**

## STEP 2 — Verify essential dependencies (and pick a Python)
Run `bin/apsy-check.sh --versions` — the focused dep + version check that reports:
- **apsy python**: the interpreter resolved via `--python > $VIRTUAL_ENV > $APSY_PYTHON > python3 from PATH` + the source label,
- **dependencies**: `psynet`, `dallinger`, and the stats stack (`pandas`/`scipy`/`statsmodels`) — installed versions if importable, ❌ if not,
- **versions (PyPI)**: installed vs latest, when `--versions` is passed,
- **summary**: one line — *"all essential dependencies present and current"* / *"N missing → /apsy:install"* / *"N outdated → /apsy:update"*.

Then:
- If `missing > 0` (psynet or dallinger or stats stack not installed): **offer to dispatch
  `apsy:install`** via `AskUserQuestion`. That skill owns the venv/interpreter decision (it offers to
  create a managed venv at `~/.auto-psynet/venv` and record `APSY_PYTHON`, or accepts an opt-out
  interpreter path for conda/poetry/uv users via `--python PATH`). Do not continue past STEP 2 with
  missing dependencies.
- If `outdated > 0` (installed but PyPI has a newer version): **offer to dispatch `apsy:update`** via
  `AskUserQuestion`. The user can decline (e.g. pinned env), and setup continues.
- If `drifted > 0` (installed version doesn't match `APSY_PSYNET_VERSION` recorded in config — e.g.
  the venv changed underneath us): note it and re-record by running `apsy:install` once or just
  refresh `APSY_PSYNET_VERSION` from the importable module.

On success, `apsy:install` records `APSY_PSYNET_PATH` so recipe references resolve. Only `psynet`,
`dallinger`, and the stats stack are required — the plugin has no other runtime dependencies.

## STEP 3 — LLM-participant backend
Detect `OPENAI_API_KEY` and `OPENROUTER_API_KEY` in the environment.
- **If a key is present:** confirm which provider to use and ask the user to name the model (e.g.
  `gpt-4o`, or any OpenRouter model id). Record `APSY_LLM_PROVIDER` + `APSY_LLM_MODEL`.
- **If no key is present:** use `AskUserQuestion` to offer (a) **ambient Claude** — LLM participants are
  driven via Claude Code subagents (no extra key, no extra cost), or (b) **set a key now** — then record
  the provider + model. Record `APSY_LLM_PROVIDER=ambient` for (a).

Rationale: the orchestrator is always the ambient Claude; the *participant* model is configured here, and
keeping it distinct from the orchestrator is methodologically cleaner (see `config/ethics-policy.md` §2).
**Do not proceed until a backend is chosen.**

## STEP 4 — Project directory
Ask for the **project directory** — the root where future `/apsy:idea` runs will scaffold new
experiments (so every study lands at `<APSY_PROJECT_DIR>/<study>/` for a uniform layout). Default
recommendation: a dedicated dir under HOME or the user's work tree, e.g.
`~/research/apsy-experiments` or `/work/<lab>/<user>/apsy-experiments`. Validate the path exists +
is writable (create it if not); reject paths inside the plugin repo. Record `APSY_PROJECT_DIR`.
**If the user has no preference, accept `$HOME/apsy-experiments` as the default.** (This setting
can be changed any time via `/apsy:project-dir`.) Data exports stay at PsyNet's
`~/psynet-data/export/` — see `apsy:project-dir` skill for symlinking that into the project tree.

## STEP 5 — Identity & server naming
Ask for the **username** used as the EC2 server-name prefix (`{username}.{study}.{host}`). Ask for the
**base domain** the user controls (for EC2 DNS) and confirm the default AWS region `us-east-1`. Record
`APSY_USERNAME`, `APSY_BASE_DOMAIN`, `APSY_AWS_REGION`. (Actual AWS-cred validity is checked by `doctor`.)

## STEP 6 — Consent default
Note that consent defaults to PsyNet `MainConsent`. Tell the user: *"You can set a custom consent form
via `apsy:consent`."* Record `APSY_CONSENT=MainConsent` unless already customized.

## STEP 7 — Persist & hand off
Write all `APSY_*` values (including `APSY_PSYNET_PATH`) to `~/.auto-psynet/config` via `bin/apsy-common.sh`. Summarize the resulting
config (redacting any key values). Recommend the user run **`/apsy:doctor`** next to validate the runtime.
**Validation gate:** confirm the config file exists and is non-empty before reporting success.
