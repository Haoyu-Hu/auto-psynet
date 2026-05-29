# Auto-PsyNet — quality gates

Auto-PsyNet drives a research project through 5 stages (FORMULATE → BUILD → PILOT & DEPLOY →
ANALYZE → PUBLISH). Between the stages sit **7 quality gates** (G1–G7) — checkpoints that must
pass before the project can advance. This document explains what gates are, why they exist,
what each gate checks, and how they interact with the plugin's autonomy levels.

If you've seen references to "G1", "G2", … in the README, `COMMANDS.md`, or any
`/apsy:*` command and weren't sure what they meant, start here.

## What is a gate?

A **gate** is a scored checklist run automatically at the end of a stage. It asks: *"Is this
piece of work good enough to build on?"* If yes → the plugin advances `state.json` to the next
stage. If no → the plugin loops back to the appropriate earlier step with concrete fixes.

Gates exist because behavioral research has well-documented failure modes that are easy to slip
into without a checkpoint:

- **p-hacking / HARKing** — analyzing after seeing the data, then pretending the analysis was
  planned. Auto-PsyNet *preregisters* the analysis at G1 and *verifies* the executed analysis
  matches it at G6.
- **Selective exclusions** — choosing who counts after seeing whose data favors your
  hypothesis. G5 enforces preregistered exclusion rules deterministically.
- **Synthetic-data laundering** — letting LLM-piloted "subjects" be reported as if they were
  humans. G3 / G5 / G6 require synthetic data to be labeled in every export and report.
- **Unethical deployment** — real money on real participants without IRB review or a wage
  floor. G4 hard-blocks deployment without explicit human approval, IRB attestation, and a
  spend cap.

The seven gates encode these defenses as **runnable rubrics**, not policy documents — the
plugin reads `config/gates/G<N>.yaml`, scores each item, and acts on the result.

## Hard items vs advisory items

Every gate rubric distinguishes:

- 🛑 **hard** — the gate cannot pass while a hard item fails. The plugin will not advance the
  stage; the user must address it. Examples: G1's `analysis_locked`, G2's
  `psynet_test_local_green`, G4's `irb_attestation`.
- ⚠️ **advisory** — the gate flags the issue, requires the user to **explicitly acknowledge**
  it (recorded in `<experiment>/.apsy/decisions.md`), then passes. Examples: G1's
  `statistical_power`, G2's `timeline_matches_plan`.
- **mixed** — hard for some contexts, advisory for others (e.g. G6's `measurement_invariance`
  is hard for cross-cultural designs, advisory otherwise).

A gate **passes** when no hard item fails and all advisory failures are acknowledged. The full
rubrics, with every item the gate checks, live in
[`config/gates/G1.yaml` … `G7.yaml`](config/gates/).

## The seven gates

```
FORMULATE →[G1] BUILD →[G2] PILOT & DEPLOY →[G3/G4] ANALYZE →[G5/G6/G7] PUBLISH
   plan         code           synthetic + humans      data           ship/iterate
```

### G1 — Plan Verified  (end of FORMULATE)

Run by `apsy:plan-review` at the end of `/apsy:idea`. Verifies that the research plan is
defensible **before any code is written**.

- 🛑 The analysis plan is **locked** (§6 of the plan, treated as a holdout for the rest of
  the project).
- 🛑 The chosen PsyNet paradigm can actually implement the design.
- 🛑 A consent module is the first element in the timeline.
- 🛑 Target pay meets the **wage floor** (default $10/hr).
- 🛑 Ethics screen: no deception-without-debrief, no vulnerable-pop without protocol.
- ⚠️ Construct validity, internal validity, statistical power, multiplicity strategy.

**On pass:** state advances to BUILD; the plan is preregistered. **On fail:** loop back to the
flagged FORMULATE step (`/apsy:idea`).

### G2 — Build Verified  (end of BUILD)

Run by `apsy:test-experiment` at the end of `/apsy:build`. Verifies the generated PsyNet
experiment actually runs and honors the PsyNet codegen contract.

- 🛑 `psynet test local` exits 0; bot tests pass for the configured `test_n_bots`.
- 🛑 Every `Page` / `Trial` declares a `time_estimate`.
- 🛑 Every `Module` / `TrialMaker` `id_` is globally unique.
- 🛑 Every `Control` has a `bot_response` (so bot tests cannot `NotImplementedError`).
- 🛑 The consent module is the first element in the timeline (ethics §1.1).
- 🛑 No `Page` / `Control` instance is reused across timeline elements (a silent-fail PsyNet
  gotcha).
- 🛑 Static paradigms use `nodes=`; chain/network paradigms use `start_nodes=`.
- ⚠️ Timeline matches §4 of the locked plan; `psynet update-scripts` clean; `requirements.txt`
  pinned.

**On pass:** state advances to PILOT. **Never marked passed without an actual green `psynet
test local`.** **On fail:** loop back to BUILD (`/apsy:build`).

### G3 — Pilot Verified  (end of PILOT)

Run at the end of `/apsy:pilot`. Stress-tests the **pipeline** — build → run → export →
analyze — on synthetic LLM-participant data. **This does NOT validate human findings**; LLMs
may bias signal, and synthetic data is never presented as human data.

- 🛑 The LLM pilot ran end-to-end; `psynet export local` produced CSVs.
- 🛑 No async/render errors in the run log.
- 🛑 The preregistered analysis script executes on pilot data without error.
- 🛑 LLM answers parse cleanly into the expected control schema (<5% retry rate).
- 🛑 Full participant transcript saved in `.apsy/pilot-transcripts/` for auditability.
- 🛑 All exports tagged `provenance=synthetic_llm_pilot`; participants tagged `is_llm=true`
  with `subject_model`.
- ⚠️ Cost within `llm_pilot.cap_usd`; obvious design assumptions hold under LLM stress.

**On pass:** state advances to ANALYZE (synthetic branch) or stays at PILOT&DEPLOY for the
human branch. **On fail:** loop back to BUILD (codegen bug) or FORMULATE (design bug surfaced
by the pilot).

### G4 — Deploy Approved  (before any real human deployment) — **HARD GATE, ALWAYS**

Enforced by `apsy:deploy` and the `spend-gate` PreToolUse hook. **Never auto-passed at any
autonomy level** — including `autonomous` mode. This is the first real-money / real-people
step.

- 🛑 Explicit human approval to spend money and recruit real participants.
- 🛑 Researcher attests Cornell IRB approval or exemption (`config/ethics-policy.md` §1.2).
- 🛑 Spend cap configured in `<experiment>/.apsy/state.json` (`spend.cap_usd > 0`).
- 🛑 G2 (build) and G3 (pilot) already passed.

**On pass:** `APSY_DEPLOY_APPROVED=1` is exported for the deploy action; the attestation is
recorded in `deployment-log.md`; the `spend-gate` hook lets `psynet deploy` and recruiter
opens through. **On fail:** the hook denies the operation; no deployment, no spend.

### G5 — Data Quality  (before ANALYZE on real human data)

Run by `apsy:data-quality` before any analysis on real human data. Enforces the
**preregistered exclusion rules deterministically** — no post-hoc selection of who counts.
Synthetic-only pipelines (the G3 branch) get a lighter version of this gate; G5 is sharp for
real data.

- 🛑 Completion rate ≥ the preregistered threshold (default 0.7).
- 🛑 Target N reached (after exclusions, per arm).
- 🛑 Every applied exclusion rule was preregistered; new rules logged as deviations.
- 🛑 Exclusions implemented in code (e.g. `.apsy/analysis/exclude.py`), reproducible without
  manual editing.
- 🛑 Attention/manipulation checks have thresholds; bot screen applied.
- 🛑 Missingness < cap (default 10%) or preregistered imputation applied.
- 🛑 Duplicate-worker check (same Prolific/MTurk/Lucid id across batches).
- 🛑 Human and synthetic data are **never mixed** in the analysis input.
- 🛑 No PII in exported analysis files (worker_id hashed, IP/UA dropped).

**No advisory items — data quality must be deterministic.** **On pass:** advance to
`apsy:analyze`. **On fail:** extend recruitment (if N short) / re-export (if PII or
provenance) / halt analysis (if exclusion rule novel) — **never silently relax a
preregistered threshold.**

### G6 — Findings Verified  (end of ANALYZE)

Run by `apsy:interpret` at the end of `/apsy:analyze`. The integrity defense against HARKing,
p-hacking, and selective reporting.

- 🛑 The executed analysis matches §6 of the preregistration (model, IVs/DVs, covariates,
  contrasts, exclusion rules).
- 🛑 Any deviation is logged in `decisions.md` with rationale **and both** the preregistered
  and revised analyses reported.
- 🛑 Every reported effect has a standardized effect size + 95% CI (not just a p-value).
- 🛑 Preregistered multiplicity correction (Bonferroni / FDR / hierarchical) applied where
  multiple comparisons were planned.
- 🛑 Non-preregistered analyses labeled `(exploratory)` everywhere they appear.
- 🛑 Results reproducible: `bin/apsy-repro.sh --dry-run` succeeds from a clean checkout.
- 🛑 If pilot/synthetic data appear in any report, they are labeled as such — **no synthetic
  numbers in a 'Results' section that purports to describe humans.**
- ⚠️ Robustness/sensitivity checks; adversarial-reviewer sign-off.
- *Mixed:* measurement invariance — hard for cross-cultural designs.

**On pass:** advance to G7. **On fail:** document the gap, re-analyze for hard items, or
demote the claim to "exploratory".

### G7 — Iterate or Ship  (end of the inner loop)

Run at the end of the inner BUILD ⇄ PILOT ⇄ ANALYZE loop. Unlike the other gates, G7 is a
**decision**, not a deficiency check: *are we satisfied with the state of the project, or do
we run another iteration?*

- 🛑 G6 (Findings Verified) PASS for this iteration.
- 🛑 An explicit SHIP or ITERATE decision recorded in `.apsy/decisions.md`.
- 🛑 If ITERATE: one-paragraph rationale + one concrete change scoped to one stage.
- 🛑 If SHIP: result is novel and defensible vs. literature in §8 of the plan; effect
  direction matches preregistration or is documented as exploratory.
- 🛑 Cumulative spend within cap; if iterating, project remaining-budget.
- ⚠️ Iteration count within the preregistered cap (default 3).

**On SHIP:** advance to PUBLISH (`/apsy:paper`); freeze `.apsy/` as the iteration-of-record.
**On ITERATE:** loop to the stage named in the rationale; bump `state.json:iteration`.

## Gates × autonomy levels

`/apsy:run` and the individual stage commands honor `autonomy_level` in `state.json`:

| Autonomy level | Soft gates (G1, G2, G3, G5, G6) | G4 (deploy) | G7 (ship/iterate) |
|---|---|---|---|
| **`supervised`** (default) | pause at every gate | **HARD pause** | pause for explicit human decision |
| **`semi_autonomous`** | auto-advance when no hard item fails | **HARD pause** | pause for explicit human decision |
| **`autonomous`** | auto-advance when no hard item fails | **HARD pause** | may auto-decide *iff* G6 passed, `ship_readiness` holds, iteration cap not exceeded, and adversarial-reviewer concurs — otherwise pause |

The three properties of G4 — **always HARD, never auto-passed, requires explicit human
approval + IRB attestation + spend cap** — hold at every autonomy level. This is the
plugin's strongest invariant: no deployment without explicit human sign-off.

## Where the actual rubrics live

- [`config/gates/G1.yaml` … `G7.yaml`](config/gates/) — the runnable scoring rubrics. Each
  item has an `id`, a `check` string, and a `level` (`hard` / `advisory` / `mixed`). Each
  gate's `pass_when` and `on_fail` fields are the authoritative pass criteria and
  loop-back targets.
- [`config/ethics-policy.md`](config/ethics-policy.md) — the constitutional document that G1
  and G4 source their hard items from. Edit this to change what the gates enforce, without
  touching skill logic.
- [`config/blind-spots/`](config/blind-spots/) — methodologist-style heuristics consulted by
  G1 (e.g. `measurement-invariance.yaml`).
- The per-experiment gate scores are recorded in
  `<experiment>/.apsy/state.json:gates.G<N>`, with acknowledged advisories in
  `<experiment>/.apsy/decisions.md`.

## See also

- [`README.md`](README.md) — install and quick start.
- [`COMMANDS.md`](COMMANDS.md) — every `/apsy:*` command, with the gate(s) each one
  triggers.
- [`project-plan/03-architecture.md`](project-plan/03-architecture.md) §3.4 — design-level
  rationale for the gate model.
- [`project-plan/01-vision-and-scope.md`](project-plan/01-vision-and-scope.md) — the
  research-integrity failures the gates were designed to defend against.
