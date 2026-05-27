---
name: wire-timeline
description: "BUILD step — assemble the full participant timeline: consent → instructions → prescreens → demography → trial maker(s) → feedback → debrief, composing PsyNet's built-in modules. Consent defaults to MainConsent (override via apsy:consent)."
---

# apsy:wire-timeline — assemble the timeline

> EXECUTION CONTRACT. Apply the **psynet-engineer** persona. Writes the `Timeline(...)` in `experiment.py`.
> **Compose PsyNet's built-in modules — don't reinvent them.**

## STEP 1 — Consent (first)
Default `MainConsent()`. If `apsy:consent` recorded a custom form, import it from its file and instantiate
per the recorded usage (e.g. `consent_x(DURATION=.., PAYMENT=..)`). Consent is the FIRST element.

## STEP 2 — Instructions
An `InfoPage` from the plan's task description (`time_estimate`).

## STEP 3 — Prescreens + demography
Add the PsyNet modules named in §4 — e.g. `HeadphoneTest` / `ColorBlindnessTest` / `AttentionTest`
(prescreen) and `Age` / `Gender` / `BasicDemography` (demography). Place prescreens before trials.

## STEP 4 — Trial maker(s)
Insert the implemented trial maker(s).

## STEP 5 — Feedback / debrief
Optional per-trial feedback (`show_feedback`); a final debrief `InfoPage`.

## STEP 6 — Invariants
Consent first; every page/PageMaker has a `time_estimate`; all `id_`s unique; no reused instances.

**Validation gate:** the timeline begins with a consent element, every page has `time_estimate`, and
`experiment.py` parses. Set `bin/apsy-state.sh set next_action "run apsy:test-experiment"`.
