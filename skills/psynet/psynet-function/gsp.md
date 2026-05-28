# Recipe: Gibbs Sampling with People — GSP (`GibbsTrialMaker`) — ★ FLAGSHIP

**Archetype / domains:** `representation_recovery` → perception, music_audio, aesthetics, categorization.
The flagship differentiator, anchored on the perception/mental-representation focus.

**When to use:** recover the distribution / shape of a **mental representation or perceptual prior** over
a continuous space (e.g. the prototypical "happy" prosody, a color prior, a pleasant chord). Participants
adjust one dimension per trial; the chain converges toward a stationary distribution. Media variants
synthesize each vector into audio/image/video — PsyNet's sweet spot for auditory/musical dimensions.

**PsyNet classes (subclass + override):**
- `MyNode(GibbsNode)` — `vector_length`, `random_sample(self, i)` (initial value per dimension). For
  media: subclass a `*GibbsNode` and define `synth_function(self, vector, output_path, chain_definition)`
  plus `vector_ranges` and `granularity`.
- `MyTrial(GibbsTrial)` — `time_estimate`; `show_trial` renders a `SliderControl` (or media + slider)
  over the currently active dimension.
- `MyTrialMaker(GibbsTrialMaker)` (or `AudioGibbsTrialMaker` / `ImageGibbsTrialMaker` / …) — `id_`,
  `start_nodes` (list for `chain_type="across"`, lambda for `"within"`), `chains_per_experiment` /
  `chains_per_participant`, `trials_per_node`, `max_nodes_per_chain`, `recruit_mode`, `balance_across_chains`.

**bot_response:** slider controls take `bot_response=<float|lambda>`; the LLM-participant driver supplies
a value conditioned on the rendered (described) stimulus.

**Gotchas:** chains use `start_nodes=` (not `nodes=`); media synthesis can be slow — set `n_jobs`; define
`vector_ranges` + `granularity` for media-GSP; remember `balance_across_chains`.

**Worked examples (installed psynet):** `psynet/trial/gibbs.py` + `media_gibbs.py`; demos `demos/experiments/gibbs/`, `gibbs_audio/` when present.

**Data shape:** per-node vectors across chain iterations → analyze the converging / stationary
distribution. Export gives the Trial CSV + node tables carrying the vectors.

**Status:** implemented — template `config/templates/experiment_gsp.py.tmpl` shipped (22 placeholders, all 8 gotchas respected incl. `start_nodes=` and `balance_across_chains`); validated end-to-end on synthetic chains (color-GSP demo, 2026-05-28: R̂<1.05 on all dims; chains converged to a warm-yellow region). Next: media-GSP (audio / image variants with `synth_function`).
