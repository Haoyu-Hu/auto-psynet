#!/usr/bin/env bash
# apsy-recruit — recruitment monitoring for a live deployment (Track B). Thin: most recruitment runs
# through the PsyNet/Dallinger dashboard + the recruiter (Prolific/Lucid/MTurk) UI. This wrapper checks
# the runtime and reminds the spend cap; the recruit skill drives the monitoring loop (incremental
# export + apsy-data-quality.py + spend tracking).
# Usage: apsy-recruit.sh status [experiment_dir]
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config
cmd="${1:-status}"; target="${2:-$PWD}"

command -v psynet >/dev/null 2>&1 || { echo "❌ psynet not installed — recruitment ops need the runtime. Run /apsy:doctor."; exit 3; }

case "$cmd" in
  status)
    echo "[apsy] recruitment status for $target"
    echo "• Live counts: use the PsyNet deployment dashboard (printed at deploy) / the recruiter's UI."
    echo "• Quality: 'psynet export ...' then bin/apsy-data-quality.py <export> --target-n <N>."
    echo "• Spend: track against the cap in .apsy/state.json (spend.cap_usd); pause if approaching it."
    ;;
  *)
    echo "usage: apsy-recruit.sh status [experiment_dir]"; exit 2;;
esac
