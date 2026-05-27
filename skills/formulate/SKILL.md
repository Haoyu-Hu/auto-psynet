---
name: formulate
description: "FORMULATE step 1 — turn a raw research idea into a structured question, falsifiable hypotheses, and operationalized variables (IV/DV → measures/stimuli). Use at the start of a new experiment or when the user runs /apsy:idea."
---

# apsy:formulate — idea → question, hypotheses, variables

> EXECUTION CONTRACT. Apply the **methodologist** persona (`agents/methodologist.md`). Writes §1–§3 of
> `.apsy/research-plan.md`. **Ground in the user's actual intent — never invent domain specifics; ask.**

## STEP 1 — Ensure the experiment workspace
Run `bin/apsy-state.sh init` to scaffold `.apsy/` from `config/templates/` (idempotent). If no short
label/abbreviation was given, ask for one (`AskUserQuestion`) — it becomes the experiment label and the
EC2 `{study}` slug. Then `bin/apsy-state.sh set label "<label>"` and `set stage FORMULATE`.
**Do not proceed until `.apsy/` exists.**

## STEP 2 — Capture the raw idea
Record the user's idea verbatim near the top of `.apsy/research-plan.md` (replace `{{LABEL}}`).

## STEP 3 — Structure it (methodologist lens)
Derive — asking the user to resolve ambiguity rather than guessing:
- **Research question** — 1–2 precise sentences.
- **Hypotheses** — directional, falsifiable H1 (+ H0), with the predicted direction and rationale.
- **Operationalization** — IV(s) + levels; DV(s) + the concrete measure; constructs → candidate stimuli.
- **Archetype + domain** — name the question archetype (representation-recovery / threshold /
  transmission / interaction / function-mapping / generate-evaluate / judgment) and the behavioral
  domain. These drive `design` and the affinity matrix.

## STEP 4 — Write the plan
Write §1 (Question), §2 (Hypotheses), §3 (Variables) of `.apsy/research-plan.md`, recording the archetype
+ domain in §3.

## Handoff
Do **not** assert an effect exists or pre-judge results. Hand off to **`apsy:design`** (or
`apsy:literature-ground` first if grounding is wanted).

**Validation gate:** §1–§3 non-empty; archetype + domain named.
