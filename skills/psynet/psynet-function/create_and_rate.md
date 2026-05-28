# Recipe: Create-and-Rate (`CreateAndRateTrialMakerMixin`)

**Archetype / domains:** `generate_evaluate` → aesthetics, creativity, stimulus validation,
selection-based cultural evolution.

**When to use:** combine **creator** trials (participants produce content) with **rater / selector**
trials (others evaluate or choose among the creations). Used for stimulus validation or
selection-driven cultural evolution.

**PsyNet classes (subclass + override):**
- Compose `CreateAndRateTrialMakerMixin` with a chain trial maker (e.g. an imitation or graph chain).
- A **creator** `Trial` (produce content) + a **rater/selector** `Trial` (evaluate/choose); both need
  `time_estimate` + `bot_response`.
- The mixin routes creations to raters and feeds selections forward to the next generation.

**bot_response:** the creator control returns content; the rater/selector control returns a rating/choice.

**Gotchas:** define exactly how ratings/selections feed the next generation; balance the creator vs.
rater roles; consult the tutorial for the composition pattern.

**Worked example (installed psynet):** `psynet/trial/create_and_rate.py` + PsyNet's create-and-rate tutorial.

**Data shape:** creations + their ratings/selections per generation.

**Status:** recipe ready.
