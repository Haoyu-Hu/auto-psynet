---
name: generate-stimuli
description: "BUILD step (as needed) — create, source, or organize the stimulus set, or wire synth_function for generative paradigms (e.g. media-GSP); register media as PsyNet Assets."
---

# apsy:generate-stimuli — stimuli & assets

> EXECUTION CONTRACT. Apply the **psynet-engineer** persona. Use when stimuli are non-trivial (media,
> large sets, or generated).

## STEP 1 — Determine the stimulus space
From §3–§4, fix the stimulus dimensions + count, tied to N and counterbalancing.

## STEP 2 — Produce / register
- **Text / numeric:** build the `STIMULI` list directly.
- **Media (audio/image/video):** place files under the experiment's `static/`, or build nodes from a
  `participant_group/block/file` tree with `compile_nodes_from_directory`; register media via `asset()`
  / `Asset(...)`.
- **Generative (media-GSP):** implement `synth_function(self, vector, output_path, chain_definition)`
  with `vector_ranges` + `granularity` (+ `n_jobs` for parallel synthesis).

## STEP 3 — Wire nodes
Attach stimuli/assets to nodes; verify the set covers the planned design and is balanced.

**Validation gate:** nodes cover the planned design; any referenced assets resolve.
