# Recipe: Adaptive psychophysics — staircase (`GeometricStaircaseTrialMaker`)

**Archetype / domains:** `threshold` → perception, psychophysics.

**When to use:** efficiently estimate a **detection / discrimination threshold** by adapting stimulus
intensity trial-to-trial along a **geometric (multiplicative) staircase** (e.g. pitch or loudness
discrimination thresholds).

**PsyNet classes (subclass + override):**
- Staircase state/node — the staircase parameters (start intensity, step factor, target reversals).
- `MyTrial` (staircase trial) — `time_estimate`; presents the stimulus at the current intensity with a
  2AFC / yes-no control.
- `MyTrialMaker(GeometricStaircaseTrialMaker)` — step factor, number of reversals, stopping rule.

**bot_response:** the control gets `bot_response`; a psychometric bot can respond as a function of the
current intensity (useful for testing convergence).

**Gotchas:** steps are **geometric** (multiply, don't add); define a reversal-based stopping rule;
threshold = mean of the last *k* reversals.

**Worked example (installed psynet):** `psynet/trial/staircase.py`; demo `demos/experiments/staircase_pitch_discrimination/` when present.

**Data shape:** per-trial intensity + response; reversal points → a threshold estimate per participant.

**Status:** recipe ready.
