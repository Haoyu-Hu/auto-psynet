# PsyNet function: Assets & stimuli

**What:** the media/stimulus system (audio, image, video, generated stimuli).

**Key API:** `Asset` + the `asset()` factory (`psynet/asset.py`); storage backends `LocalStorage` /
`S3Storage` / `WebStorage`; assets attach to Node / Trial / Participant / Module / Network / Experiment.
Modes: cached / on-demand / generated. Configure with `asset_storage` on the `Experiment` (and the
`docker_volumes` mapping for the assets dir).

**Stimulus building:**
- `compile_nodes_from_directory()` — build nodes from a `participant_group/block/file` media tree.
- Generative paradigms (media-GSP) — `synth_function(self, vector, output_path, chain_definition)` with
  `vector_ranges`, `granularity`, and `n_jobs` (parallel synthesis).

**Gotchas:** large sets → `docs/tutorials/large_stimulus_sets`; synthesis is slow (use `n_jobs`); register
assets so the front-end can serve them; keep generated media out of git (regenerate from code).
