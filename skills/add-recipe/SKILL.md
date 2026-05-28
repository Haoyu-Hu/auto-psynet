---
name: add-recipe
description: "Add a new PsyNet recipe file under skills/psynet/psynet-function/ (a new paradigm or cross-cutting capability) and auto-update the parent index in skills/psynet/SKILL.md. Use when extending the PsyNet knowledge pack with something not yet covered — e.g. a new TrialMaker subclass, a new prescreen, a new asset workflow, or a domain-specific recipe."
---

# apsy:add-recipe — extend the PsyNet knowledge pack

> EXECUTION CONTRACT. Adds a new file under `skills/psynet/psynet-function/` + inserts a row into the
> parent index. **Always show the file content + index row before writing.** Refuses to overwrite an
> existing recipe without explicit consent.

## STEP 1 — Gather inputs
Ask via `AskUserQuestion`:
- **name** (kebab-case or snake_case): filename slug, e.g. `audio_staircase` or `multi-arm-bandit`.
  Must match `^[a-z][a-z0-9_-]{0,39}$`.
- **category**: `paradigm` (new TrialMaker recipe) / `cross-cutting` (new capability — i18n, payment,
  prescreen, asset workflow, …).
- **purpose**: one-line description for the index row + top of the recipe.
- For `paradigm` only — **trial_maker**: the PsyNet `TrialMaker` class name (e.g.
  `StaticTrialMaker`, `GibbsTrialMaker`). The engine derives the matching `Trial` base by stripping
  `Maker`.
- Optional: pass `--from <path>` to copy an existing `.md` as the base instead of using the template.

## STEP 2 — Preview
Run `bin/apsy-add-recipe.py --dry-run` with the gathered args. The engine prints:
- the target file path,
- the templated content,
- the row that will be inserted into the matching table in `skills/psynet/SKILL.md`.

Show the dry-run output and `AskUserQuestion` to confirm before writing.

## STEP 3 — Write + index
Re-run the engine without `--dry-run`. It:
- writes `skills/psynet/psynet-function/<name>.md`,
- inserts the new row into the right table (`## Paradigm recipes` or `## Cross-cutting PsyNet
  functions`) in `skills/psynet/SKILL.md`,
- prints the next-step checklist.

## STEP 4 — Validate
Run `bash tests/validate-assembly.sh` to confirm the new file + index update don't break the plugin's
assembly checks.

## STEP 5 — Hand-off
Open the new recipe file. If `--from` was used, the content is the source file and the user can edit
in place. Otherwise the file has `TODO` placeholders for: archetype/domains, when-to-use, classes,
`bot_response` (paradigm only), gotchas, worked-example path, data shape (paradigm only), status.

**Optional follow-ups** for a `paradigm` recipe:
- Add the paradigm id to `config/affinity.yaml` (which question-archetypes it serves).
- Expand the recipe by invoking `apsy:design` or `apsy:implement-paradigm` against the new recipe —
  the `psynet-engineer` persona will populate the worked-example pointer against the installed psynet
  (located via `APSY_PSYNET_PATH`).

**PROHIBITED:** silently overwriting an existing recipe; editing the parent index by hand instead of
through the engine (the row format must match the existing table style for the parser).

**Validation gate:** `tests/validate-assembly.sh` green; new file present; parent index row present.
