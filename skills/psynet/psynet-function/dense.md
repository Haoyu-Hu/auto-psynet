# Recipe: Dense rating / psychophysics (`DenseTrialMaker`)

**Archetype / domains:** `function_mapping`, `threshold` → perception, psychophysics.

**When to use:** **densely sample a continuous stimulus space** to map a response function or measure
discrimination. Specialized trial types: `SliderCopyTrial`, `SameDifferentTrial`, `AXBTrial`,
`SingleStimulusTrial`, `PairedStimulusTrial`.

**PsyNet classes (subclass + override):**
- `MyTrialMaker(DenseTrialMaker)` (subclasses `StaticTrialMaker`) with the chosen specialized trial type.
- The trial subclass — `time_estimate`; `show_trial` per the type (slider / AXB / same-different).
- Nodes sample the continuous space (often parametric / generated).

**bot_response:** each control gets `bot_response` (a slider value, or the AXB / same-different choice).

**Gotchas:** like static, uses `nodes=`; **pick the trial type to match the question** — AXB &
same-different for discrimination, slider-copy for matching, single/paired for rating.

**Worked example:** `materials/psynet/psynet/trial/dense.py` + the dense demos.

**Data shape:** stimulus coordinate + response per trial → the response function over the space.

**Status:** recipe ready.
