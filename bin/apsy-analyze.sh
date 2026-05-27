#!/usr/bin/env bash
# apsy-analyze — run the preregistered analysis script on the exported data. Real stats, not narration.
# Usage: apsy-analyze.sh [analysis_script] [data_dir]
set -uo pipefail
script="${1:-.apsy/analysis/analysis.py}"
data="${2:-data}"

command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
if [[ ! -f "$script" ]]; then
  echo "❌ no analysis script at '$script'."
  echo "   The analyze skill writes it from §6 of the plan + config/templates/analysis.py.tmpl."
  exit 1
fi

echo "[apsy] running preregistered analysis: $script   (data: $data)"
python3 "$script" "$data"
rc=$?
[[ $rc -eq 0 ]] && echo "✅ analysis ran; results in .apsy/analysis/results.json" \
                || echo "❌ analysis failed (rc=$rc) — fix the script or check the data path/columns."
exit $rc
