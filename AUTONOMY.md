# Auto-PsyNet — autonomy levels

Auto-PsyNet can run on a spectrum from *you-confirm-every-step* to *let-it-run-itself*. The
**autonomy level** is the dial that controls this. It is a per-experiment setting (lives in
`<experiment>/.apsy/state.json`), defaults to **`supervised`**, and is read by every stage
command (`/apsy:idea`, `/apsy:build`, `/apsy:pilot`, `/apsy:analyze`, `/apsy:paper`) as well
as by the autonomous pipeline (`/apsy:run`).

If you've seen references to "autonomy_level", "supervised mode", or "autonomous mode" in the
README, `COMMANDS.md`, or `GATES.md` and weren't sure what they meant, start here.

## The dial in one paragraph

You're going to spend time and (eventually) money on this research project. The autonomy level
tells the plugin how often to stop and ask you before proceeding. **The lower the autonomy,
the more checkpoints; the higher the autonomy, the more the plugin acts on its own** — but
the safety-critical step (gate G4, real human deployment) is **always** a hard checkpoint that
requires explicit human approval, IRB attestation, and a spend cap, regardless of the level
you pick. This invariant is the plugin's strongest guarantee.

## The three levels

| Level | Soft gates (G1, G2, G3, G5, G6) | G4 (deploy) | G7 (ship/iterate) | Default? |
|---|---|---|---|---|
| **`supervised`** | pause for human at every gate | **HARD pause** (always) | pause for explicit human decision | ✅ |
| **`semi_autonomous`** | auto-advance when no hard item fails; pause on any failure | **HARD pause** (always) | pause for explicit human decision | |
| **`autonomous`** | auto-advance when no hard item fails | **HARD pause** (always) | may auto-decide *iff* G6 passed + ship-readiness + iteration cap + adversarial reviewer concurs | |

### `supervised` (default)

The plugin pauses at every quality gate (G1, G2, G3, G5, G6) and at every stage transition,
showing you the gate result and waiting for you to confirm before advancing. Use this when:

- You're new to Auto-PsyNet and want to see what each step produces.
- The experiment is high-stakes (sensitive domain, large planned sample, novel paradigm).
- You're iterating on the design and want to inspect intermediate artifacts.
- You're debugging a pipeline issue and want fine control.

This is the **safest mode**. Every decision you'd normally make — *is the plan good? does the
generated code look right? is the pilot data sane? does the analysis match preregistration?*
— is surfaced to you for explicit approval.

### `semi_autonomous`

The plugin auto-advances through the soft gates **when no hard item fails**. If any hard item
fails, it pauses and shows you the failure (same as supervised). G4 still **always** pauses
for the four hard requirements (human approval, IRB, spend cap, G2+G3 green). G7
(ship/iterate decision) also always pauses — that's a judgment call, not a checklist. Use
this when:

- You've already shipped one project with Auto-PsyNet and trust the soft-gate scoring.
- The design is well-understood (a paradigm + domain you've used before).
- You want to drive several variants in parallel without baby-sitting each.
- You're running synthetic-only iterations (no human spend) and the soft gates are reliable
  signals of progress.

Advisory items at each gate still get acknowledged + logged in `decisions.md` — the plugin
doesn't silently brush them aside; it just doesn't stop to ask "did you see this?" for every
one.

### `autonomous`

The plugin auto-advances through soft gates **and** G7 (ship-vs-iterate), provided all of
these hold: G6 passed, ship-readiness criteria met (novel + defensible + effect direction
matches preregistration), iteration cap not exceeded, and the **adversarial-reviewer**
persona concurs. Otherwise G7 pauses for an explicit human decision. G4 still
**always** pauses for the four hard requirements.

Use this when:

- You're running an LLM-pilot-only sweep (`/apsy:run` without `--with-deployment`) — there's
  no real spend, no real participants, and the question is "does this experiment hold up
  end-to-end on synthetic data."
- You've validated the design on multiple prior projects and the adversarial-reviewer
  catches most issues anyway.
- You're prototyping rapidly and willing to re-do an iteration if the auto-decision turns out
  to be wrong.

**`autonomous` does NOT mean "skip checks"** — the gates still run, hard items still block,
and synthetic data is still labeled. It means "I trust the rubric scoring to make the
soft-gate calls and the ship-vs-iterate decision when the rubric is unambiguous."

## The invariants (true at every level)

These hold regardless of autonomy:

1. **G4 always pauses.** Real human deployment requires explicit human approval, an IRB
   attestation, a configured spend cap, and green G2+G3. There is no autonomy level that
   bypasses any of these. (`config/ethics-policy.md` §3, enforced by the `spend-gate`
   PreToolUse hook.)
2. **Autonomy never softens HARD items.** `semi_autonomous` and `autonomous` may auto-advance
   when no hard item fails; they will not auto-advance through a hard failure at any gate.
   (`config/ethics-policy.md` §5.)
3. **Synthetic data is always labeled.** No autonomy level lets LLM-pilot results be
   presented as human data (G3, G5, G6 all check this; `config/ethics-policy.md` §2.4).
4. **Deviations from the preregistration are always logged.** Even in `autonomous` mode, G6
   requires every deviation to be in `decisions.md` with both the preregistered and revised
   analyses reported.

If you set the autonomy level higher and something safety-critical fails, the plugin **stops
and surfaces the failure** rather than working around it.

## Setting and changing the level

The autonomy level is a per-experiment setting in `<experiment>/.apsy/state.json`. The default
on `apsy:idea` scaffolding is `"supervised"`.

```bash
# inspect (reads state.json)
bash bin/apsy-state.sh read | python3 -c 'import json,sys;print(json.load(sys.stdin)["autonomy_level"])'

# change for the current experiment
bash bin/apsy-state.sh set autonomy_level semi_autonomous
bash bin/apsy-state.sh set autonomy_level autonomous
bash bin/apsy-state.sh set autonomy_level supervised
```

You can change it mid-project — the next stage command picks up the new value. Common patterns:

- **Start at `supervised`** through G1 (locking the plan); bump to `semi_autonomous` for the
  BUILD ⇄ PILOT loop; drop back to `supervised` when iterating on the design.
- **Stay at `supervised`** the whole way for high-stakes deployments — the marginal
  inconvenience is small compared to the safety it gives.
- **Use `autonomous`** for synthetic-only `/apsy:run` jobs where you're exploring a paradigm
  variant; review the output afterwards.

## How `/apsy:run` interacts with autonomy

`/apsy:run` walks the full FORMULATE → BUILD → PILOT → ANALYZE → PUBLISH pipeline. Its
behavior:

- Reads `autonomy_level` at the start of each stage from `state.json`.
- Pauses according to the table above at each gate.
- On `--with-deployment`, adds the real-human branch — G4 still hard-blocks until the four
  approval conditions are satisfied (no autonomy level changes this).
- Is **resumable**: re-running `/apsy:run` picks up from the current `state.json:stage` —
  including the autonomy level you may have changed since the last run.

For day-to-day stage commands (`/apsy:idea`, `/apsy:build`, etc.), the autonomy level affects
the **gate score handling**: how the command treats an advisory-only failure (auto-ack in
non-supervised vs. ask in supervised) and whether stage transitions happen automatically.

## State & resume

The autonomy level travels with the experiment:

- Lives in `<experiment>/.apsy/state.json:autonomy_level`.
- Read by every stage command, by `/apsy:run`, and by the gate rubrics.
- Survives session restarts (it's on disk, not in chat memory).
- Per-experiment, not global — different experiments can run at different levels.

If you `/apsy:status`, the reported next action reflects the current autonomy level (e.g.
"next: confirm G2 pass and advance to PILOT" in supervised vs. "next: G2 will auto-advance if
clean" in semi_autonomous).

## See also

- [`GATES.md`](GATES.md) — what each gate (G1–G7) actually checks, and why G4 is the always-
  hard invariant.
- [`COMMANDS.md`](COMMANDS.md) — every `/apsy:*` command, with the autonomy-sensitive ones
  (`/apsy:run`, `/apsy:analyze`, `/apsy:deploy`) noted.
- [`config/ethics-policy.md`](config/ethics-policy.md) §5 — the formal invariant "autonomy
  never softens HARD items".
- [`config/templates/state.json`](config/templates/state.json) — the default state file
  scaffolded by `apsy:idea` (`autonomy_level` defaults to `"supervised"`).
- [`config/gates/G4.yaml`](config/gates/G4.yaml) and
  [`config/gates/G7.yaml`](config/gates/G7.yaml) — the two gates whose pass criteria depend
  on autonomy level.
