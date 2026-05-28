# Recipe: MCMC with People — MCMCP (`MCMCPTrialMaker`)

**Archetype / domains:** `representation_recovery` → perception, categorization, emotion, social judgment.

**When to use:** sample from the distribution over a mental **category / representation** via a
Metropolis-style **2-alternative forced choice**: each trial shows the current state + a proposal, the
participant picks which better fits the category, and accepted proposals become the next state. Converges
to the category distribution. A discrete-choice cousin of GSP — use when responses are choices, not sliders.

**PsyNet classes (subclass + override):**
- `MyNode(MCMCPNode)` — defines the state space and the **proposal function** (how a new candidate is
  proposed from the current state).
- `MyTrial(MCMCPTrial)` — `time_estimate`; `show_trial` presents the two candidates (current vs proposal)
  with a 2AFC control.
- `MyTrialMaker(MCMCPTrialMaker)` — chain config (`start_nodes`, `chain_type`, `chains_per_*`,
  `max_nodes_per_chain`, `trials_per_node`, `recruit_mode`).

**bot_response:** the 2AFC control gets `bot_response=<choice|lambda>`; the LLM driver picks the option
matching the described category.

**Gotchas:** chains use `start_nodes=`; tune the proposal distribution (step size drives mixing); both
candidates must render clearly and comparably.

**Worked example:** the installed psynet package (`psynet/trial/mcmcp.py`; demo `demos/experiments/mcmcp/` when present) (verify Node/Trial class
names against it).

**Data shape:** per-trial chosen vs rejected state; the accepted-state sequence per chain → the
stationary distribution.

**Status:** recipe ready (verify against the runtime).
