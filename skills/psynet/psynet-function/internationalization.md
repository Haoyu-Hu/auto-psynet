# PsyNet function: Internationalization / cross-cultural (`psynet translate`)

**What:** run the same experiment across languages and locales — the basis for **cross-cultural** studies.

**Key API:** `get_translator()` → `_` and `get_translator(context=True)` → `_p`; wrap user-facing strings
as `_("text")` / `_p("context", "text")` (prompts, instructions, consent). The `psynet translate` CLI
extracts and manages translations; configure locales. The **Lucid** recruiter reaches global panels.
Reference: `docs/tutorials/internationalization.rst`; the example consent
real lab consent modules use `_p` throughout.

**Use for:** the cross-cultural/multilingual differentiator. **Always pair cross-group comparisons with a
measurement-invariance check** (configural/metric/scalar) — see `config/blind-spots/measurement-invariance.yaml`.

**Gotchas:** wrap every participant-facing string in the translator before extraction; supply per-locale
translations; never compare a construct across cultures without establishing invariance first.

**Status:** implemented — skill `skills/localize/SKILL.md` shipped (8-step execution contract);
blind-spot `config/blind-spots/measurement-invariance.yaml` shipped (3 levels + 5 pitfalls + G6
reporting checklist); validated end-to-end on synthetic data (multilingual-pleasantness demo,
2026-05-28: configural PASS, metric FAIL on de-es pair, scalar PASS — decision rule correctly
restricted the cross-cultural interpretation).
