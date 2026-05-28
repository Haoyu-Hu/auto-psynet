# PsyNet function: Synchronization & real-time multiplayer (`SyncGroups`)

**What:** multiple participants — and/or **LLM agents** — act together in a synchronized group, in real
time. The substrate for interacting-network experiments and **human-AI hybrid** designs.

**Key API:** `sync_group_type` on chain/trial makers; `SyncGroups`; wait pages — `wait_while(condition,
...)` and `WaitPage`; `advance_past_wait_pages(bots)` to step synchronized bots in tests.
Docs: PsyNet's synchronization tutorial (`docs/tutorials/synchronization.rst` in the PsyNet docs).

**Use for:** coordination/economic games, networked transmission (with `graph_chain`), and human-AI
hybrid groups (mix human participants with LLM participants via `bin/apsy_llm_participant.py`).

**Gotchas:** real-time adds **timing, dropouts, and turn-taking** complexity — build the **async** form
first; synchronous bot tests need deterministic bots + `advance_past_wait_pages`; design barrier/wait
points explicitly with `wait_while`/`WaitPage`.

**Status:** async hybrid implemented — `bin/apsy_llm_participant.py` drives LLM-side responses via
OpenAI/OpenRouter; validated on synthetic data in the hybrid-chain demo (2026-05-28) with the
`experiment_imitation_chain.py.tmpl` template. **Real-time sync (`sync_group_type ≠ None`) still
recipe-only** — needs verification against the live psynet runtime; cf. the `graph_chain.md` recipe
which exposes `sync_group_type` as the next-step lever.
