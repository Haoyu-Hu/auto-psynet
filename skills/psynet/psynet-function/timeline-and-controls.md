# PsyNet function: Timeline, pages & controls

**Timeline:** `Timeline(elt, elt, ...)` — an ordered list of elements; the participant's position is a
list index. Auto-appends successful-end logic.

**Building blocks:**
- `ModularPage(label, prompt, control, time_estimate)` = a `Prompt` (what's shown) + a `Control` (how
  they respond). `InfoPage(content, time_estimate)` for display-only.
- `PageMaker(fn, time_estimate)` — a page computed at runtime from participant state.
- `CodeBlock(fn)` — side effects, no screen. `Module(id_, *elts)` — named grouping.

**Control flow:** `conditional`, `switch`, `while_loop`, `for_loop`, `randomize`, `sequence` (pass
`fix_time_credit`/`expected_repetitions` to keep progress + payment estimates sane); `wait_while`/`WaitPage`.

**Control catalog (each takes `bot_response`; each exposes `metadata` = its affordances, which the
LLM-participant driver reads):** `PushButtonControl` / `RadioButtonControl` / `CheckboxControl` /
`DropdownControl` (OptionControl — `choices`/`labels`), `SliderControl`, `TextControl`, `NumberControl`,
audio-recording controls, `SurveyJSControl`, `NullControl`. Prompts: text/`Markup`, `AudioPrompt`,
`ImagePrompt`, `VideoPrompt`.

**Gotchas:** every Page/PageMaker needs `time_estimate`; use `Markup` for HTML; unique `id_`s; never reuse
an object instance; **`bot_response` on every control**.
