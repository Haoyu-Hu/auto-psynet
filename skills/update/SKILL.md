---
name: update
description: "Upgrade PsyNet and/or Dallinger in the active Python environment to a specified or the latest version. Use when the user says 'update psynet', 'upgrade dallinger', 'bump deps to latest', or after /apsy:doctor reports an outdated version. Reports old → new version diff; never auto-upgrades inside an experiment directory's pinned env without explicit confirmation."
---

# apsy:update — upgrade PsyNet + Dallinger

> EXECUTION CONTRACT. Mutates the active Python environment with `pip install --upgrade`. **Always
> show the upgrade plan and ask the user to confirm before running pip.** Refuse to silently upgrade
> inside a project whose `requirements.txt` / `pyproject.toml` pins a different version.

## STEP 1 — Preflight (what's installed today)
- Resolve the "apsy python" via the engine's priority chain
  (`--python > $VIRTUAL_ENV > $APSY_PYTHON > python3`). Show which interpreter will be upgraded + the
  source label (engine prints both: e.g. `python: ~/.auto-psynet/venv/bin/python (APSY_PYTHON in ...)`).
- Read current versions: `<apsy python> -c 'import psynet; print(psynet.__version__)'` and the same
  for `dallinger`. If either is **not installed**, do not "upgrade" — hand off to `/apsy:install`.
- Read `~/.auto-psynet/config` for `APSY_PSYNET_VERSION` / `APSY_DALLINGER_VERSION` (last recorded by
  `apsy:install` or a previous `apsy:update`) and note any mismatch with what's actually importable
  (a sign the venv changed underneath us).
- If the user wants to target a different interpreter for this upgrade (e.g. a separate conda env),
  accept `--python PATH` via `$ARGUMENTS` and pass it straight to the engine.

## STEP 2 — Project-pinning safety check
If the current working dir contains `requirements.txt`, `pyproject.toml`, `setup.cfg`, or
`environment.yml` that pins a `psynet==X` or `dallinger==X` line, **warn the user**: upgrading will
desync the env from the project pin. Ask via `AskUserQuestion` whether to (a) skip, (b) upgrade
anyway, or (c) update the project pin afterwards.

## STEP 3 — Choose the target version
Ask via `AskUserQuestion`:
- PsyNet target: **latest** (default) / a specific version (e.g. `13.0.5`) / **keep current** (skip).
- Dallinger target: **latest** (default) / specific / keep current.

Skip the prompt if the user passed an explicit `--psynet VER` / `--dallinger VER` via `$ARGUMENTS`.

## STEP 4 — Plan + confirm
Run `bin/apsy-install.sh --upgrade --dry-run` with the chosen flags. The engine prints the exact
`pip install --upgrade ...` command and the resolved dependency tree. Show:
- **before:** `psynet=<current>   dallinger=<current>` (engine prints this).
- **plan:** the pip command.
- **diff:** which packages will change versions (skim the "Would install" lines).

Then `AskUserQuestion` to confirm proceeding with the real upgrade. **Do not run the upgrade without
explicit confirmation.**

## STEP 5 — Execute
Run `bin/apsy-install.sh --upgrade` with the chosen `--psynet` / `--dallinger` flags. On success the
engine prints:

```
✅ upgraded:
   psynet     13.0.5 → 13.2.0
   dallinger  11.5.7 → 12.2.0
```

and records the new versions + path into `~/.auto-psynet/config`.

If pip fails: show the tail of the error. Common cases: missing build deps (gcc, postgresql-dev),
PEP-668 (`externally-managed-environment` — offer venv path, do not auto-pass
`--break-system-packages`), version conflict (an installed package pins an incompatible psynet — ask
the user how to resolve).

## STEP 6 — Verify
Run `bin/apsy-doctor.sh` (or invoke `apsy:doctor`) to confirm the upgraded versions are importable and
the recorded path resolves. If the user is inside an experiment directory, remind them to:
- re-run `psynet debug` to catch any breakage from the upgrade.
- consider re-running `/apsy:lint-rules` and the `/apsy:simulate` smoke if the upgrade crossed a major
  version (e.g. PsyNet 12 → 13).

**PROHIBITED:** silently downgrading; passing `--break-system-packages` without consent; upgrading
inside a project whose pin file says otherwise without surfacing the conflict.

**Validation gate:** `apsy:doctor` reports the new psynet + dallinger versions ✅ after upgrade.
