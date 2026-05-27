#!/usr/bin/env bash
# apsy-test — run the experiment's bot tests (gate G2). Returns 0 only when bots pass.
# Usage: apsy-test.sh [target_dir]
set -uo pipefail
target="${1:-$PWD}"

if ! command -v psynet >/dev/null 2>&1; then
  echo "❌ psynet not installed — cannot run G2 (psynet test local)."
  echo "   Run /apsy:doctor; install psynet locally or use an EC2 runtime."
  exit 3
fi
if [[ ! -f "$target/experiment.py" ]]; then
  echo "❌ no experiment.py in $target — scaffold/implement first."
  exit 1
fi

echo "[apsy] G2 → psynet test local   (in $target)"
( cd "$target" && psynet test local )
rc=$?
if [[ $rc -eq 0 ]]; then
  echo "✅ G2 PASSED — bots completed the experiment without failure."
else
  echo "❌ G2 FAILED (rc=$rc) — fix the experiment and re-run. Common causes: missing time_estimate,"
  echo "   duplicate id_, a Control without bot_response, or a render/async error."
fi
exit $rc
