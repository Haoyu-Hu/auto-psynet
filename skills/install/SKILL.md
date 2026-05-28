---
name: install
description: "Install Auto-PsyNet's essential dependencies — PsyNet + Dallinger (with optional version pinning) and the Python stats stack — into a chosen Python interpreter. Use when /apsy:doctor reports psynet missing, when the user says 'install apsy/psynet', or after first cloning the plugin. Auto-detects venv/APSY_PYTHON; offers to create a managed venv at ~/.auto-psynet/venv on first run. Never breaks system packages without explicit opt-in."
---

# apsy:install — auto-install PsyNet + Dallinger

> EXECUTION CONTRACT. Mutates the active Python environment. **Always present the install plan and ask
> the user to confirm before running pip.** Never pass `--break-system-packages` without explicit
> consent. Never silently install into system Python when a managed venv is the safer option.

## STEP 1 — Pick the Python interpreter

Auto-PsyNet's interpreter priority (highest first):
```
--python PATH  >  $VIRTUAL_ENV/bin/python  >  $APSY_PYTHON (~/.auto-psynet/config)  >  python3 from PATH
```

Detect:
- `$VIRTUAL_ENV` — an active venv in this shell?
- `$APSY_PYTHON` from `~/.auto-psynet/config` — a previously-recorded managed Python?
- `python3 --version` and writability of its site-packages (PEP-668 risk).

Then choose one of three paths via `AskUserQuestion`:

| Case | Path |
|------|------|
| `$VIRTUAL_ENV` active | Use it. Inform the user; no prompt needed. |
| `$APSY_PYTHON` set + executable | Use it. Inform the user; offer to switch to a managed venv if they want. |
| Neither — **recommended default** | **Offer to create a managed venv at `~/.auto-psynet/venv/`** (engine flag `--create-venv`). This records `APSY_PYTHON` so subsequent `apsy:install`/`apsy:update`/`apsy:doctor` calls use the same Python. |
| Conda/poetry/uv user — opt-out | Ask for an explicit interpreter path (engine flag `--python /path/to/python`). Optionally also write it to config (`APSY_PYTHON`) so it persists. |

## STEP 2 — Choose versions
Ask via `AskUserQuestion` (defaults are fine if the user has no preference):
- PsyNet version: **latest** (default) / a specific pinned version (e.g. `13.0.5`).
- Dallinger version: **latest** (default) / a specific pinned version.
- Install the Python stats stack (`pandas`/`scipy`/`statsmodels`) if missing? **Yes** (default) / No.

## STEP 3 — Plan + confirm
Show the resolved plan with `bin/apsy-install.sh --dry-run` plus the chosen interpreter flags
(`--create-venv` / `--python PATH`). The engine prints which interpreter it will use + the source
(`(--python override)` / `(active VIRTUAL_ENV)` / `(APSY_PYTHON in ...)` / `(python3 from PATH)`),
then runs `pip --dry-run` so the user sees the exact specs + the resolved dependency tree. Then
`AskUserQuestion` to confirm proceeding with the real install. **Do not run the install without
explicit confirmation.**

## STEP 4 — Execute
Run `bin/apsy-install.sh` with the chosen flags. The engine:
- creates the managed venv (if `--create-venv`) and records `APSY_PYTHON` in `~/.auto-psynet/config`,
- runs `pip install` into the chosen interpreter,
- records `APSY_PSYNET_VERSION`, `APSY_DALLINGER_VERSION`, and `APSY_PSYNET_PATH` on success.

If pip fails with PEP-668 (`externally-managed-environment`): tell the user, **do not auto-add**
`--break-system-packages`; recommend `--create-venv` (preferred) or have them re-run with the flag if
they accept the consequences.

## STEP 5 — Verify
Run `bin/apsy-doctor.sh` (or invoke `apsy:doctor` skill) to confirm:
- "apsy python" reports the chosen interpreter + source.
- `psynet` / `dallinger` are importable by that Python.
- Stats stack importable.

Report the verified versions and the next step (Docker/Postgres/Redis for local runtime, or the EC2
path).

**PROHIBITED:** running pip without showing the plan; using `--break-system-packages` silently;
silently installing into system Python when no venv is active (always offer `--create-venv` first);
upgrading inside an experiment directory's pinned environment without explicit confirmation.

**Validation gate:** `apsy:doctor` reports psynet + dallinger ✅ after install, using the chosen
`apsy python`.
