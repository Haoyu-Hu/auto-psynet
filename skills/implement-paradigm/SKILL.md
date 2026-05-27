---
name: implement-paradigm
description: "BUILD step — fill the scaffolded experiment.py with the Trial/Node/TrialMaker code for the chosen paradigm, from its psynet-function recipe and the verified plan. Enforces the PsyNet gotchas and wires bot_response."
---

# apsy:implement-paradigm — write the paradigm code

> EXECUTION CONTRACT. Apply the **psynet-engineer** persona. This turns `{{PLACEHOLDERS}}` into real code.

## STEP 1 — Load recipe + plan
Read `skills/psynet/psynet-function/<paradigm>.md` (the recipe; via the `apsy:psynet` index) and `.apsy/research-plan.md` §3–§5 (variables, design,
N). Cite the worked example the recipe points to (`materials/psynet/demos/...`, `experiment-examples/`).

## STEP 2 — Stimuli / nodes
From §3–§4, build the stimulus list / nodes. For non-trivial sets or media, call `apsy:generate-stimuli`.

## STEP 3 — Implement the classes
Fill the template placeholders: the `Trial` subclass (`show_trial` → `ModularPage(prompt, control)` with
`time_estimate` + `bot_response`), node config, and the `TrialMaker` instantiation (`id_`,
`nodes=`/`start_nodes=` per paradigm, trials + `target_n_participants` from §4–§5). For a paradigm with
no template yet, author `experiment.py` directly from the recipe.

## STEP 4 — Enforce the gotchas (the `psynet-lint` hook also reminds)
`time_estimate` everywhere; globally-unique `id_`; never reuse an object instance; `bot_response` on
every Control; static uses `nodes=`, chains `start_nodes=`; `Markup` for HTML; consent first.

## STEP 5 — Record
`bin/apsy-state.sh set next_action "run apsy:wire-timeline"`.

**Validation gate:** no `{{PLACEHOLDER}}` remains in the paradigm/trial section, and the file parses
(`python3 -c "import ast,sys; ast.parse(open('experiment.py').read())"`).
