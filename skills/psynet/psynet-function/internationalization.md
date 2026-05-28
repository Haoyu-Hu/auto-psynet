# PsyNet function: Internationalization / cross-cultural (`psynet translate`)

**What:** run the same experiment across languages and locales — the basis for **cross-cultural** studies.

**Key API:** `get_translator()` → `_` and `get_translator(context=True)` → `_p`; wrap user-facing strings
as `_("text")` / `_p("context", "text")` (prompts, instructions, consent). The `psynet translate` CLI
extracts and manages translations; configure locales. The **Lucid** recruiter reaches global panels.
Reference: `docs/tutorials/internationalization.rst`; the example consent
real lab consent modules use `_p` throughout.

**Use for:** the cross-cultural/multilingual differentiator. **Always pair cross-group comparisons with a
measurement-invariance check** (configural/metric/scalar) — see `config/blind-spots/methodology.md`.

**Gotchas:** wrap every participant-facing string in the translator before extraction; supply per-locale
translations; never compare a construct across cultures without establishing invariance first.
