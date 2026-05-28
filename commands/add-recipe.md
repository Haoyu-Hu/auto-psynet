---
command: add-recipe
description: Add a new PsyNet recipe file under skills/psynet/psynet-function/ and auto-update the parent index.
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# apsy:add-recipe — extend the PsyNet knowledge pack

Run the **`apsy:add-recipe`** skill to add a new file under `skills/psynet/psynet-function/` (a new
paradigm or cross-cutting capability) and auto-insert it into the parent index in
`skills/psynet/SKILL.md`.

Pass parameters via `$ARGUMENTS`, e.g.

```
/apsy:add-recipe --name audio_staircase --category paradigm --trial-maker StaticTrialMaker \
                 --purpose "audio-stimulus adaptive staircase"
```

With no args, the skill prompts for everything. Use this when teaching Auto-PsyNet about a paradigm or
capability it doesn't know yet — e.g. a new `TrialMaker` subclass, a new prescreen, or a new asset
workflow.
