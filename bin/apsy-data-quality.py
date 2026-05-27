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

    if "failed" in df.columns:
        failed = int(df["failed"].astype(str).str.lower().isin(["true", "1", "t", "yes"]).sum())
        out["checks"].update(n_failed=failed, n_valid=n - failed,
                             completion_rate=round((n - failed) / n, 3) if n else None)
    for col in ("status", "progress", "aborted"):
        if col in df.columns:
            out["checks"][f"{col}_counts"] = df[col].value_counts(dropna=False).head(10).to_dict()

    att = [c for c in df.columns if "attention" in c.lower() or "catch" in c.lower()]
    if att:
        out["checks"]["attention_columns"] = att

    for idc in ("worker_id", "unique_id", "prolific_id", "participant_id"):
        if idc in df.columns:
            dups = int(df[idc].duplicated().sum())
            out["checks"][f"duplicate_{idc}"] = dups
            if dups:
                out["flags"].append(f"{dups} duplicate {idc}")
            break

    valid = out["checks"].get("n_valid", n)
    if a.target_n:
        out["checks"]["target_n"] = a.target_n
        out["checks"]["target_met"] = valid >= a.target_n
        if valid < a.target_n:
            out["flags"].append(f"target N not met ({valid}/{a.target_n})")

    out["verdict"] = "review" if out["flags"] else "ok"
    print(json.dumps(out, indent=2, default=str))


if __name__ == "__main__":
    main()
