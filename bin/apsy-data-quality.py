#!/usr/bin/env python3
"""apsy data-quality — generic screening over a PsyNet data export (gate G5).

Operates on an export directory (per-class CSVs) or a single participant CSV. Tolerant of which columns
are present (PsyNet exports vary). Prints a JSON summary + an advisory verdict; the data-quality skill
applies the *preregistered* exclusion rules on top of this.

Usage: apsy-data-quality.py <export_dir_or_csv> [--target-n N]
"""
import argparse, json, pathlib, sys
try:
    import pandas as pd
except ImportError:
    print(json.dumps({"error": "pandas not installed — see /apsy:doctor"})); sys.exit(2)


def find_participant_csv(path):
    p = pathlib.Path(path)
    if p.is_file():
        return p
    for d in (p, p / "data", p / "regular" / "data"):
        if d.is_dir():
            for name in ("Participant.csv", "participant.csv"):
                if (d / name).exists():
                    return d / name
            for f in sorted(d.glob("*.csv")):
                try:
                    cols = pd.read_csv(f, nrows=0).columns
                    if {"failed", "status", "progress"} & set(cols):
                        return f
                except Exception:
                    pass
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--target-n", type=int, default=0)
    a = ap.parse_args()

    out = {"source": str(a.path), "checks": {}, "flags": []}
    pcsv = find_participant_csv(a.path)
    if pcsv is None:
        out["error"] = "no participant-like CSV found"
        print(json.dumps(out, indent=2)); sys.exit(1)

    df = pd.read_csv(pcsv)
    out["participant_csv"] = str(pcsv)
    n = len(df)
    out["checks"]["n_rows"] = n

    # Detect trial-level vs participant-level shape (PsyNet's <TrialClass>.csv is trial-level — one row
    # per trial, many rows per participant; Participant.csv is participant-level). Two signals
    # combined: (a) presence of `trial_index` / `is_repeat_trial` columns (strong; PsyNet trial-CSVs
    # always carry these); (b) avg-rows-per-participant ratio (weak fallback when columns ambiguous).
    pid_col = next((c for c in ("worker_id", "unique_id", "prolific_id", "participant_id")
                    if c in df.columns), None)
    trial_marker_cols = [c for c in ("trial_index", "is_repeat_trial", "active_index", "node_id", "iteration") if c in df.columns]
    is_trial_level = False
    n_participants = None
    if pid_col:
        n_participants = int(df[pid_col].nunique())
        # Strong signal: trial-marker column present → trial-level
        if trial_marker_cols and n_participants > 0:
            is_trial_level = True
        # Fallback signal: many rows per participant
        elif n_participants > 0 and n / n_participants >= 1.5:
            is_trial_level = True
    out["checks"]["shape"] = "trial-level" if is_trial_level else "participant-level"
    if is_trial_level:
        out["checks"]["n_unique_participants"] = n_participants
        out["checks"]["avg_trials_per_participant"] = round(n / n_participants, 2)
        if trial_marker_cols:
            out["checks"]["trial_markers_detected"] = trial_marker_cols

    if "failed" in df.columns:
        failed = int(df["failed"].astype(str).str.lower().isin(["true", "1", "t", "yes"]).sum())
        out["checks"]["n_failed_rows"] = failed
        if is_trial_level and pid_col:
            # completion = participants who have NO failed trial
            failed_mask = df["failed"].astype(str).str.lower().isin(["true", "1", "t", "yes"])
            n_complete = int(df[~failed_mask][pid_col].nunique() if (~failed_mask).any() else 0)
            out["checks"]["n_complete_participants"] = n_complete
            out["checks"]["completion_rate"] = round(n_complete / n_participants, 3) if n_participants else None
        else:
            out["checks"].update(n_failed=failed, n_valid=n - failed,
                                 completion_rate=round((n - failed) / n, 3) if n else None)

    for col in ("status", "progress", "aborted"):
        if col in df.columns:
            out["checks"][f"{col}_counts"] = df[col].value_counts(dropna=False).head(10).to_dict()

    att = [c for c in df.columns if "attention" in c.lower() or "catch" in c.lower()]
    if att:
        out["checks"]["attention_columns"] = att

    if pid_col and not is_trial_level:
        # Duplicate-id check only meaningful for participant-level data.
        dups = int(df[pid_col].duplicated().sum())
        out["checks"][f"duplicate_{pid_col}"] = dups
        if dups:
            out["flags"].append(f"{dups} duplicate {pid_col}")

    # Target-N comparison: against unique participants when trial-level; against valid rows otherwise.
    if a.target_n:
        out["checks"]["target_n"] = a.target_n
        denom = n_participants if is_trial_level else out["checks"].get("n_valid", n)
        out["checks"]["target_met"] = (denom or 0) >= a.target_n
        if (denom or 0) < a.target_n:
            out["flags"].append(f"target N not met ({denom}/{a.target_n})")

    out["verdict"] = "review" if out["flags"] else "ok"
    print(json.dumps(out, indent=2, default=str))


if __name__ == "__main__":
    main()
