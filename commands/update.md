---
command: update
description: Upgrade PsyNet and/or Dallinger to a specified or the latest version in the active Python env.
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# apsy:update — upgrade PsyNet + Dallinger

Run the **`apsy:update`** skill to upgrade the installed PsyNet and/or Dallinger. The skill checks
what's currently installed, warns if the project directory pins a different version, shows the
upgrade plan via `pip --dry-run`, asks you to confirm, then runs the upgrade and verifies via
`/apsy:doctor`.

Specify a target version with `$ARGUMENTS`: e.g. `/apsy:update --psynet 13.2.0` or
`/apsy:update --dallinger latest`. With no flags, the skill prompts and defaults to latest.

If PsyNet / Dallinger aren't installed yet, the skill hands off to `/apsy:install` instead.
