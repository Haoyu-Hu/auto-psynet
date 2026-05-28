# Recipe: Network / graph chains (`GraphChainTrialMaker` + `SyncGroups`)

**Archetype / domains:** `interaction` → social, economic, collective behavior; also the substrate for
**human-AI hybrid** networks.

**When to use:** generalize chains to **arbitrary network topologies** and/or **interacting
participants** — coordination games, networked transmission, collective dynamics. Combine with
`SyncGroups` for real-time multiplayer (see [`synchronization.md`](synchronization.md)).

**PsyNet classes (subclass + override):**
- `MyNode(GraphChainNode)` — content + the graph topology linking nodes (who feeds whom).
- `MyTrial(GraphChainTrial)` — `time_estimate`; `show_trial` for the (possibly interactive) task.
- `MyTrialMaker(GraphChainTrialMaker)` — the topology spec, `sync_group_type` for synchronous play,
  plus chain/recruit config.

**bot_response:** every control gets `bot_response`; for **hybrid** runs the LLM-participant driver fills
them; synchronous tests need deterministic bots + `advance_past_wait_pages`.

**Gotchas:** real-time sync adds timing/dropout complexity — **do async first**; define the topology
explicitly; use `wait_while` / `WaitPage` for coordination points.

**Worked example:** PsyNet graph demos + `docs/tutorials/synchronization.rst`.

**Data shape:** node/edge states over rounds; per-participant and per-network records.

**Status:** implemented (async) — template `config/templates/experiment_graph_chain.py.tmpl` shipped (23 placeholders, `start_nodes=` + `balance_across_chains=True` + `sync_group_type=None` per the async-first gotcha); validated end-to-end on synthetic trees (network-demo, 2026-05-28: per-depth statistics + variance-growth + anchoring analysis ran honestly with an integrity-gate "partial confirmation" verdict). Next: sync version (`sync_group_type ≠ None`) for real-time / hybrid runs — verify against the runtime.
