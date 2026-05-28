---
command: install
description: Auto-install Auto-PsyNet's essential dependencies — PsyNet + Dallinger (with optional version pinning) + the Python stats stack.
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# apsy:install — install PsyNet + Dallinger

Run the **`apsy:install`** skill to install the essential dependencies in the active Python env. The
skill detects venv vs `--user`, shows the install plan via a pip dry-run, asks you to confirm before
actually installing, then records the installed versions to `~/.auto-psynet/config` and re-runs
`/apsy:doctor` to verify.

Specify a version with `$ARGUMENTS`: e.g. `/apsy:install --psynet 13.0.5 --dallinger 11.5.7`. Defaults
to latest stable on PyPI. Pass `--stats` to also install `pandas`/`scipy`/`statsmodels` if missing.
