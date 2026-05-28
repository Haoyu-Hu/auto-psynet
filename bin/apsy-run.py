#!/usr/bin/env python3
"""apsy-run — autonomous-pipeline state machine for /apsy:run.

Given `.apsy/state.json`, compute the next action and the autonomy decision (auto-advance vs. pause for
the human). The `apsy:run` skill loops calling this and dispatching the recommended skill.

Pipeline:  FORMULATE → BUILD → PILOT → [DEPLOY] → ANALYZE → PUBLISH
Gates:     G1         G2     G3      G4(hard)   G5/G6/G7  (G7 hard by default)

Autonomy (from state.autonomy_level):
  - supervised      → pause at every gate.
  - semi_autonomous → auto-advance SOFT gates (G1/G2/G3/G5/G6); pause at G4 (always) + G7.
  - autonomous      → auto SOFT + G7; **G4 ALWAYS PAUSES** (real money / real people; ethics §1.2,§3).

Synthetic-only by default; set `state.run.with_deployment = true` (or `--with-deployment`) to add the
real-human Track B branch — G4 still hard-blocks until approval + IRB attestation + spend cap.

Usage:  apsy-run.py next  [--state PATH]  [--with-deployment]
Output: JSON on stdout.
"""
import argparse
import json
import pathlib
import sys

SOFT_GATES = {"G1", "G2", "G3", "G5", "G6"}
HARD_GATES = {"G4", "G7"}


def find_state():
    d = pathlib.Path.cwd().resolve()
    while True:
        p = d / ".apsy" / "state.json"
        if p.is_file():
            return p
        if d.parent == d:
            return None
        d = d.parent


def autopass(autonomy, gate):
    """Does the autonomy level permit auto-advancing this gate transition?"""
    if autonomy == "supervised":
        return False
    if autonomy == "semi_autonomous":
        return gate in SOFT_GATES        # G4 + G7 always pause
    if autonomy == "autonomous":
        return gate in SOFT_GATES or gate == "G7"  # G4 still hard
    return False


def _frame(state, with_dep):
    return {
        "stage": state.get("stage", "FORMULATE"),
        "iteration": int(state.get("iteration", 0) or 0),
        "max_iterations": int(state.get("max_iterations", 1) or 1),
        "autonomy": state.get("autonomy_level", "supervised"),
        "with_deployment": with_dep,
        "done": False,
        "halted": False,
    }


def compute_next(state, with_dep):
    out = _frame(state, with_dep)
    stage = out["stage"]
    gates = state.get("gate_statuses", {}) or {}
    autonomy = out["autonomy"]
    iteration, max_iter = out["iteration"], out["max_iterations"]

    def nxt(skill, command, gate, reason, auto=None):
        return {
            **out,
            "next": {
                "skill": skill, "command": command, "gate": gate,
                "autopass": autopass(autonomy, gate) if auto is None else bool(auto),
                "reason": reason,
            },
        }

    def halt(reason):
        return {**out, "halted": True, "next": {"reason": reason}}

    if stage == "FORMULATE":
        g = gates.get("G1", "pending")
        if g == "pending":
            return nxt("apsy:idea", "/apsy:idea", "G1",
                       "FORMULATE stage; run /apsy:idea to draft the plan + G1 review", auto=False)
        if g == "pass":
            return nxt("apsy:build", "/apsy:build", "G2",
                       "G1 passed; advance to BUILD")
        return halt(f"G1={g} → human revision required before proceeding")

    if stage == "BUILD":
        g = gates.get("G2", "pending")
        if g == "pending":
            return nxt("apsy:build", "/apsy:build", "G2",
                       "BUILD stage; scaffold + implement + wire-timeline + test (G2)", auto=False)
        if g == "pass":
            return nxt("apsy:pilot", "/apsy:pilot", "G3",
                       "G2 passed; advance to PILOT (LLM participants)")
        return halt(f"G2={g} → `psynet test local` not green; fix and rerun")

    if stage == "PILOT":
        g = gates.get("G3", "pending")
        if g == "pending":
            return nxt("apsy:pilot", "/apsy:pilot", "G3",
                       "PILOT stage; run LLM-participant pilot + G3 checks", auto=False)
        if g == "pass":
            if with_dep:
                return nxt("apsy:deploy", "/apsy:deploy", "G4",
                           "G3 passed; G4 is HARD (real humans) — always pause for human approval",
                           auto=False)
            return nxt("apsy:analyze", "/apsy:analyze", "G6",
                       "G3 passed; synthetic-only run → advance to ANALYZE")
        return halt(f"G3={g} → review pilot transcripts / fix design")

    if stage == "DEPLOY":
        g = gates.get("G4", "pending")
        if g == "pending":
            return nxt("apsy:deploy", "/apsy:deploy", "G4",
                       "G4 HARD: explicit human approval + IRB attestation + spend cap required",
                       auto=False)
        if g == "pass":
            return nxt("apsy:analyze", "/apsy:analyze", "G6",
                       "G4 passed; collection complete → ANALYZE", auto=False)
        return halt(f"G4={g} → revise and re-attest")

    if stage == "ANALYZE":
        g6 = gates.get("G6", "pending")
        g7 = gates.get("G7", "pending")
        if g6 == "pending":
            return nxt("apsy:analyze", "/apsy:analyze", "G6",
                       "ANALYZE stage; export → data-quality → analyze → interpret", auto=False)
        if g6 != "pass":
            return halt(f"G6={g6} → analysis did not match preregistration / not verified")
        if g7 == "ship":
            return nxt("apsy:paper", "/apsy:paper", None,
                       "G7 ship → PUBLISH",
                       auto=(autonomy != "supervised"))
        if g7 == "iterate":
            if iteration + 1 >= max_iter:
                return halt(f"G7 iterate but max_iterations ({max_iter}) reached — human review required")
            return nxt("apsy:build", "/apsy:build", "G2",
                       f"G7 iterate (iteration {iteration+1}/{max_iter}); loop back to BUILD")
        return nxt("apsy:iterate", None, "G7",
                   "G6 passed; run /apsy:iterate to decide ship vs iterate (G7 always pauses)",
                   auto=False)

    if stage == "PUBLISH":
        return {**out, "done": True,
                "next": {"skill": "apsy:paper", "command": "/apsy:paper", "gate": None,
                         "autopass": False,
                         "reason": "PUBLISH stage; write-paper + repro-package, then done"}}

    return halt(f"unknown stage: {stage}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("subcmd", choices=["next"], default="next", nargs="?")
    ap.add_argument("--state", default=None, help="path to a state.json (else searched from cwd)")
    ap.add_argument("--with-deployment", action="store_true",
                    help="include the real-human DEPLOY branch (Track B; G4 hard-gated)")
    a = ap.parse_args()

    sp = pathlib.Path(a.state) if a.state else find_state()
    if not sp or not sp.is_file():
        print(json.dumps({"error": "no .apsy/state.json found; run /apsy:idea to scaffold an experiment"}))
        sys.exit(1)
    state = json.loads(sp.read_text(encoding="utf-8"))
    with_dep = a.with_deployment or bool((state.get("run") or {}).get("with_deployment"))
    print(json.dumps(compute_next(state, with_dep), indent=2))


if __name__ == "__main__":
    main()
