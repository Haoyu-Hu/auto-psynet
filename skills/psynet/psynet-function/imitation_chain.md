# Recipe: Transmission chain / iterated learning (`ImitationChainTrialMaker`)

**Archetype / domains:** `transmission` → language, culture, memory, music.

**When to use:** study how content **transforms as it is passed along a chain** (serial reproduction,
iterated learning, cultural evolution) — biases accumulate over generations. `chain_type="within"` (one
participant's own chain) or `"across"` (a chain shared across participants).

**PsyNet classes (subclass + override):**
- `MyNode(ImitationChainNode)` — `create_initial_seed(self, experiment, participant)` (the starting
  content) and `summarize_trials(self, trials, experiment, participant)` (aggregate this generation's
  responses into the next seed). Default `create_definition_from_seed` passes the seed through unchanged.
- `MyTrial(ImitationChainTrial)` — `time_estimate`; `show_trial` presents the current seed + a
  reproduction control.
- `MyTrialMaker(ImitationChainTrialMaker)` — `chain_type`, `max_nodes_per_chain` (chain length),
  `chains_per_participant` / `chains_per_experiment`, `trials_per_node`.

**bot_response:** the reproduction control gets `bot_response` (e.g. `lambda: self.definition["seed"]` to
copy faithfully in tests).

**Gotchas:** chains use `start_nodes=` (lambda for within, list for across); `summarize_trials` must
return the next seed in the **same shape** as the seed; set chain length via `max_nodes_per_chain`.

**Worked example (installed psynet):** `psynet/trial/imitation_chain.py`; demo `demos/experiments/imitation_chain/` when present.

**Data shape:** per-node seeds across generations → the transformation trajectory per chain.

**Status:** implemented — template `config/templates/experiment_imitation_chain.py.tmpl` shipped (22 placeholders, honors `start_nodes=` + `summarize_trials` same-shape gotchas + `balance_across_chains=True`); validated end-to-end on synthetic data, including a **hybrid human-AI** demo (hybrid-chain, 2026-05-28: 6 chains × 10 generations alternating subject_type; mixed-sample analysis with anchor-α detected H1b cleanly; decision rule "confirm H1 — humans and LLMs introduce structurally different transmissions" fired correctly).
