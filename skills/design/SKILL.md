---
name: design
description: "FORMULATE step — choose the experimental paradigm and design. Maps the question archetype to a PsyNet paradigm via config/affinity.yaml, reads the recipe + domain priors, may propose elevating to a differentiating paradigm, and specifies conditions, counterbalancing, prescreens, population/languages, and consent."
---

# apsy:design — paradigm & design

> EXECUTION CONTRACT. Apply the **methodologist** persona. Writes §4 of `.apsy/research-plan.md`. This is
> where the plugin's **proactive design intelligence** lives.

## STEP 1 — Read inputs
Read `.apsy/research-plan.md` §1–§3 and the named **archetype** + **domain**.

## STEP 2 — Map archetype → paradigm (affinity)
Query `config/affinity.yaml`: the archetype yields candidate paradigms (a **soft prior**). Read the
matching `skills/psynet/psynet-function/<p>.md` recipe(s) and the `config/domains/<domain>.md` priors.

## STEP 3 — Recommend (proactive design intelligence)
Present the **canonical** paradigm match AND, when defensible, a **novel cross-over** with its trade-off
(e.g. "a one-shot rating works, but a cross-cultural GSP would recover the whole representation — more
powerful and more novel"). Use `AskUserQuestion`; the user chooses. Never silently lock a paradigm.

## STEP 4 — Specify the design
For the chosen paradigm, specify: conditions; within vs between; counterbalancing + randomization;
**prescreening** (PsyNet modules, e.g. `HeadphoneTest`, `AttentionTest`) + **exclusion criteria**;
**target population + languages** (cross-cultural scoping — flag **measurement invariance** if comparing
groups); and **consent** (default `MainConsent`; note `apsy:consent` for a custom form).

## STEP 5 — Write + record
Write §4 (Design). Set `bin/apsy-state.sh set paradigm "<paradigm>"`.

**Validation gate:** §4 complete; the chosen paradigm matches a known `skills/psynet/psynet-function/` recipe;
population + languages stated.
