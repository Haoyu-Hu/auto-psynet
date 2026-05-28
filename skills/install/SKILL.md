---
name: install
description: "Install Auto-PsyNet's essential dependencies — PsyNet + Dallinger (with optional version pinning) and the Python stats stack. Use when /apsy:doctor reports psynet missing, when the user says 'install apsy/psynet', or after first cloning the plugin. Detects venv vs --user automatically; never breaks system packages without explicit opt-in."
---

# apsy:install — auto-install PsyNet + Dallinger

> EXECUTION CONTRACT. Mutates the active Python environment. **Always present the install plan and ask
> the user to confirm before running pip.** Never pass `--break-system-packages` without explicit consent.

## STEP 1 — Preflight
- Detect the active Python: `python3 --version` + `${VIRTUAL_ENV:-(none)}`. Show both.
- Check current state: are `psynet` / `dallinger` already importable? If yes, show their versions and
  ask whether the user wants to *re-install* / *upgrade* (in which case hand off to `apsy:update`) or
  abort.

## STEP 2 — Choose versions
Ask via `AskUserQuestion` (defaults are fine if the user has no preference):
- PsyNet version: **latest** (default) / a specific pinned version (e.g. `13.0.5`).
- Dallinger version: **latest** (default) / a specific pinned version.
- Install the Python stats stack (`pandas`/`scipy`/`statsmodels`) if missing? **Yes** (default) / No.

## STEP 3 — Plan + confirm
Show the resolved plan with `bin/apsy-install.sh --dry-run` (it prints `pip install ...` and runs
`pip --dry-run` so the user sees the exact specs + the resolved dependency tree). Then `AskUserQuestion`
to confirm proceeding with the real install. **Do not run the install without explicit confirmation.**

## STEP 4 — Execute
Run `bin/apsy-install.sh` with the chosen flags (`--psynet VER`, `--dallinger VER`, `--stats` as
needed). The engine records `APSY_PSYNET_VERSION`, `APSY_DALLINGER_VERSION`, and `APSY_PSYNET_PATH`
into `~/.auto-psynet/config` on success.

If pip fails with PEP-668 (`externally-managed-environment`): tell the user, **do not auto-add**
`--break-system-packages`; offer the venv path (recommended) or have them re-run with the flag if they
accept the consequences.

## STEP 5 — Verify
Run `bin/apsy-doctor.sh` (or invoke `apsy:doctor` skill) to confirm:
- `psynet` CLI is on PATH + importable; `APSY_PSYNET_PATH` resolves.
- `dallinger` present.
- Stats stack importable.

Report the verified versions and the next step (Docker/Postgres/Redis for local runtime, or the EC2
path).

**PROHIBITED:** running pip without showing the plan; using `--break-system-packages` silently;
upgrading inside an experiment directory's pinned environment without explicit confirmation.

**Validation gate:** `apsy:doctor` reports psynet + dallinger ✅ after install.
