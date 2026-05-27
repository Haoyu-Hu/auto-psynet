#!/usr/bin/env bash
# apsy-export — export experiment data (psynet export local) and point at the per-class CSVs.
# Usage: apsy-export.sh [experiment_dir]
set -uo pipefail
target="${1:-$PWD}"

if ! command -v psynet >/dev/null 2>&1; then
  echo "⚠️  psynet not installed — cannot run 'psynet export'."
  echo "    If you already have an export (e.g. from a pilot or a prior run), point the analyze step at"
  echo "    its data/ directory directly."
  exit 3
fi

echo "[apsy] psynet export local  (in $target)"
( cd "$target" && psynet export local )
echo "Exports land under ~/PsyNet-data/export/ : regular/data/*.csv (one CSV per class) + anonymous/."
echo "Pass the data/ directory to the analysis (bin/apsy-analyze.sh <script> <data_dir>)."
