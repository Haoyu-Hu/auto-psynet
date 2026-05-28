---
name: localize
description: "Translate the experiment for cross-cultural / multilingual runs. Use when the research plan declares >1 locale, when running a global Lucid panel, or when measurement invariance is part of the G6 rubric. Wraps user-facing strings with the PsyNet translator (`_` / `_p`), runs `psynet translate` to extract them, and stages per-locale message catalogs. **Cross-cultural comparisons without an invariance check are an integrity violation — see config/blind-spots/measurement-invariance.yaml.**"
---

# apsy:localize — multilingual / cross-cultural setup

> EXECUTION CONTRACT. Touches user-facing strings in `experiment.py` and stages per-locale message
> catalogs. **Refuse to wire a cross-cultural comparison without a measurement-invariance check in
> §6 of the locked research plan.**

## STEP 1 — Preflight
- Read `.apsy/research-plan.md` §4: which locales are declared in "Target population & languages"?
  If only one, **stop and tell the user**: `apsy:localize` is for multi-locale runs only.
- Read §6: is a measurement-invariance check preregistered? If not, **block** with a pointer to
  `config/blind-spots/measurement-invariance.yaml` — running multi-locale without invariance is the
  textbook cross-cultural integrity violation (ethics §2.1 / §2.2).
- Confirm `psynet` is installed and on PATH (the translate pipeline lives in `psynet translate`).

## STEP 2 — Choose locales + recruiter
Ask via `AskUserQuestion` if not already in the plan:
- **Locales:** e.g. `en` (default), `es`, `de`, `zh`, `ja`. Use BCP-47 short codes. (The full
  `en_US`/`es_MX` granularity matters for some panels; `psynet translate` supports both.)
- **Recruiter:** Lucid (global panels — default for multi-locale), or Prolific (English-speakers in
  multiple countries). Configure via `apsy:lucid` / `apsy:prolific`.

## STEP 3 — Wrap user-facing strings
Scan `experiment.py` for participant-facing strings that are NOT wrapped:
- Prompts inside `Markup(...)`, `ModularPage(...)` (`label`, `prompt`).
- `MainConsent`/consent module text.
- `InfoPage` HTML.
- `PushButtonControl(choices=...)` labels, `SliderControl` axis labels, debrief text.

For each, apply the wrapping pattern from
`skills/psynet/psynet-function/internationalization.md`:
- `_("plain text")` — unambiguous strings.
- `_p("context", "ambiguous text")` — when the same English string needs different translations in
  different contexts (e.g. "right" as direction vs correctness).

**Do not** wrap strings that ship in the export CSV (e.g. condition labels, factor names) — those
are analysis-side and must stay locale-independent for cross-locale aggregation.

## STEP 4 — Extract via `psynet translate`
Run `psynet translate extract` to harvest all wrapped strings into a message catalog
(`locale/messages.pot`). Then `psynet translate init <locale>` per target locale → produces
`locale/<locale>/LC_MESSAGES/messages.po` skeleton files.

## STEP 5 — Provision translations
Two paths:
- **Human-translated** (preferred for real studies): hand the `.po` files to a translator;
  receive back filled translations; commit to the experiment repo.
- **LLM-assisted draft** (acceptable for pilots — flag as advisory): pass each `.po` `msgid` to an
  LLM with a brief context (e.g. "behavioral-experiment prompt; preserve question form"). **Tag
  every machine-translated string in `.apsy/decisions.md`** so a real run reviews them before launch.

## STEP 6 — Compile + verify locale switching
`psynet translate compile` builds `.mo` files. Then in `experiment.py`'s `config`, declare the
supported locales (`supported_locales=["en","es","de"]`) and the default. Run `psynet test local`
with the locale env var set (e.g. `PSYNET_LOCALE=es psynet test local`) to verify each locale
renders without missing-translation warnings.

## STEP 7 — Lock measurement-invariance plan
Confirm §6 of the research plan specifies which invariance levels are tested
(see `config/blind-spots/measurement-invariance.yaml`):
- **Configural:** does each locale show the same qualitative pattern (e.g. the same factor
  structure / sign of the effect)?
- **Metric:** are the magnitudes (factor loadings / effect sizes) comparable across locales?
- **Scalar:** are the intercepts (baseline ratings) comparable across locales? — the strongest
  claim, required for direct mean-comparison across locales.

For single-DV designs (rating tasks), the analogous checks are:
- **Pattern:** sign-of-effect agreement across locales.
- **Magnitude:** effect-size variability across locales (large variability → fail metric).
- **Baseline:** between-locale baseline-rating differences (large differences → fail scalar; only
  within-locale comparisons remain valid).

## STEP 8 — Hand-off to BUILD
Stamp `.apsy/decisions.md` with: locales chosen, translation provenance (human / LLM-assisted +
which model + when reviewed), invariance levels preregistered. **`apsy:build` may now scaffold the
multi-locale experiment.**

**PROHIBITED:** running cross-locale comparisons without §6 invariance checks; presenting an
LLM-translated study to humans without translator review; deleting `_` / `_p` wrappers to "fix" a
locale that isn't rendering (instead, fix the catalog).

**Validation gate:** at least one `.po` per declared locale has been provisioned; `psynet test
local` runs green under each `PSYNET_LOCALE`; §6 invariance plan present; decisions.md updated.
