#!/usr/bin/env bash
# apsy-debug — run the current experiment for debugging. Targets: local | ec2.
# Debug only; does NOT enable real recruitment (that is /apsy:deploy, gated by G4).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config

target="${1:-local}"
case "$target" in
  local)
    echo "[apsy] debug target = local → psynet debug local"
    command -v psynet >/dev/null 2>&1 || { echo "❌ psynet not installed; run /apsy:doctor"; exit 1; }
    exec psynet debug local
    ;;
  ec2)
    # Phase-1 wiring. Provisions/refreshes a Dallinger EC2 instance, then debugs over SSH.
    region="${APSY_AWS_REGION:-us-east-1}"
    echo "[apsy] debug target = ec2 (region ${region})"
    echo "Planned: dallinger ec2 provision --name ${APSY_USERNAME:-USER}.<study> \\"
    echo "           --region ${region} --type m7i.<N>xlarge --dns <study>.${APSY_BASE_DOMAIN:-DOMAIN}"
    echo "         then psynet debug ssh --app <study> (recruitment OFF)."
    echo "⚠️  EC2 wiring is implemented in Phase 1; this is the documented plan for now."
    exit 0
    ;;
  *)
    echo "usage: apsy-debug.sh {local|ec2}"; exit 2 ;;
esac
