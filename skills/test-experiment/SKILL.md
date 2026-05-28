---
name: test-experiment
description: "BUILD gate G2 — make the experiment self-verifying with bots and run `psynet test local` until green. Sets test_n_bots + test_check_bot assertions."
---

# apsy:test-experiment — gate G2 (Build Verified)

> EXECUTION CONTRACT. Apply the **psynet-engineer** persona. **The bar is a GREEN `psynet test local` —
> not your confidence. Never fake a pass.**

## STEP 1 — Make it self-verifying
Ensure `test_n_bots` is set and `test_check_bot(self, bot)` asserts sanity (at minimum `assert not
bot.failed`; ideally expected trial counts / group balance).

## STEP 2 — Run the bots
Run `bin/apsy-test.sh <experiment_dir>` (= `psynet test local`). **If psynet is absent**, report that G2
requires the runtime (`/apsy:doctor`; install psynet or use an EC2 runtime) and STOP — do not mark G2.

## STEP 3 — Fix-and-iterate on failure
Read the traceback and fix the usual culprits: missing `time_estimate`, duplicate `id_`, a Control
without `bot_response`, a reused object instance, or a render/async error. Re-run until green.

**Stuck or non-obvious failure?** Dispatch the **`debugger`** persona — it reproduces, isolates,
applies the *minimal* fix, and verifies by re-running. Never claim G2 green without an actual green run.

## STEP 4 — On green
`bin/apsy-state.sh set gate_statuses.G2 pass`; `set stage PILOT`; `set next_action "run /apsy:pilot"`.
Write `.apsy/reports/G2-build.md` (what was built, the passing test summary).

**Validation gate:** G2 passes **only** on an actual green `psynet test local`; `state.json` reflects it.
