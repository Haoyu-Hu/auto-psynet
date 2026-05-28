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

## STEP 2 — Verify essential dependencies
Confirm the **essential packages** are installed and detectable (run `bin/apsy-doctor.sh`, or check
directly): `psynet` (CLI + importable) and `dallinger`, plus the Python stats stack
(`pandas`/`scipy`/`statsmodels`). Record the psynet install location so recipe references resolve:
`APSY_PSYNET_PATH=$(python3 -c 'import psynet, os; print(os.path.dirname(psynet.__file__))')`.
If anything essential is missing, **offer to dispatch `apsy:install`** to install it (with optional
version pinning) — do not continue with missing dependencies. Only these essential packages are required — the plugin has no
other runtime dependencies.

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

## STEP 4 — Identity & server naming
Ask for the **username** used as the EC2 server-name prefix (`{username}.{study}.{host}`). Ask for the
**base domain** the user controls (for EC2 DNS) and confirm the default AWS region `us-east-1`. Record
`APSY_USERNAME`, `APSY_BASE_DOMAIN`, `APSY_AWS_REGION`. (Actual AWS-cred validity is checked by `doctor`.)

## STEP 5 — Consent default
Note that consent defaults to PsyNet `MainConsent`. Tell the user: *"You can set a custom consent form
via `apsy:consent`."* Record `APSY_CONSENT=MainConsent` unless already customized.

## STEP 6 — Persist & hand off
Write all `APSY_*` values (including `APSY_PSYNET_PATH`) to `~/.auto-psynet/config` via `bin/apsy-common.sh`. Summarize the resulting
config (redacting any key values). Recommend the user run **`/apsy:doctor`** next to validate the runtime.
**Validation gate:** confirm the config file exists and is non-empty before reporting success.
