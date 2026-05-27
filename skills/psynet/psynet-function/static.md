# Recipe: Static trials (`StaticTrialMaker`)

**Archetype / domains:** `judgment`, `function_mapping` → decision_making, attitudes, perception (any
fixed stimulus set). The MVP **stepping-stone** paradigm — simplest to get `psynet test local` green.

**When to use:** a fixed set of stimuli, each rated / classified / judged, with balanced or blocked
sampling per participant. **Not** when you need iterated, adaptive, or interactive dynamics
(use gsp / chains / networks).

**PsyNet classes (subclass + override):**
- `MyTrial(StaticTrial)` — set `time_estimate`; override `show_trial(self, experiment, participant)` to
  return `ModularPage(prompt, control, time_estimate=...)`. Optional: `score_answer`,
  `compute_performance_reward`, `show_feedback`.
- Nodes: build `StaticNode(definition={...}, block=...)` instances, passed as `nodes=[...]`.
- `MyTrialMaker(StaticTrialMaker)` — `id_` (globally unique), `trial_class=MyTrial`, `nodes=[...]`,
  `expected_trials_per_participant`, `max_trials_per_block`, `n_repeat_trials`, `recruit_mode`,
  `target_n_participants`.

**bot_response:** every `Control` gets `bot_response=<value|lambda>` (e.g.
`PushButtonControl(..., bot_response="Yes")`). The LLM-participant driver substitutes a model call.

**Gotchas:** static uses `nodes=` (NOT `start_nodes=`); `time_estimate` on the Trial + every page;
unique `id_`; never reuse a node/page object instance.

**Worked example:** `materials/psynet/demos/experiments/static/experiment.py`.

**Data shape:** `MyTrial.csv` — one row per trial with `definition` (stimulus), `answer`, `score`,
`block`, `participant_id`, `is_repeat_trial`.

**Status:** implemented-first (MVP).
