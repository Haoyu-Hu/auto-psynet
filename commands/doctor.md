---
command: doctor
description: Auto-PsyNet environment diagnostics — essential dependencies (psynet/dallinger), Docker/Postgres/Redis, LLM keys, AWS, config.
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion, Skill
---

Run the **`apsy:doctor`** skill (invoke the Skill tool with skill `apsy:doctor`) and present its
actionable checklist. Read-only unless the user approves a fix.
