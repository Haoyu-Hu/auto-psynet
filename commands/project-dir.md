---
command: project-dir
description: Set or inspect the Auto-PsyNet project directory (APSY_PROJECT_DIR) — the root where new experiments are scaffolded. Default if unset: current working directory.
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# apsy:project-dir — configure the project home

Run the **`apsy:project-dir`** skill to set or inspect `APSY_PROJECT_DIR` — the consistent root
where `/apsy:idea` scaffolds new experiments. With this set, every new study lands at
`<APSY_PROJECT_DIR>/<study>/`, giving you a uniform project layout across sessions and machines.

Pass a path via `$ARGUMENTS`, e.g. `/apsy:project-dir ~/research/apsy-experiments`. With no
argument, the skill prompts via `AskUserQuestion` and reports the current value.

**Note:** this affects where new experiment dirs are *created*. Data exports still go to PsyNet's
own location (`~/psynet-data/export/`); see the skill for how to symlink that into your project
tree if you want.
