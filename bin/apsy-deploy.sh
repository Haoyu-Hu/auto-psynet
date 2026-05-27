#!/usr/bin/env bash
# apsy-deploy — enforce the HARD G4 gate, then deploy via the pluggable adapter. Real money / real people.
# G4 (never auto-passed): G2+G3 green · spend cap set · IRB attested · human approval token present.
# Usage: apsy-deploy.sh <ssh|heroku|ec2> [experiment_dir]
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config
backend="${1:-}"; target="${2:-$PWD}"
case "$backend" in ssh|heroku|ec2) ;; *) echo "usage: apsy-deploy.sh {ssh|heroku|ec2} [experiment_dir]"; exit 2;; esac

read_state() {  # read_state <dotted.key>
  python3 - "$target/.apsy/state.json" "$1" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1])); cur = d
    for p in sys.argv[2].split("."):
        cur = cur[p]
    print(cur)
except Exception:
    print("")
PY
}

echo "== G4 gate (Deploy Approved) — config/ethics-policy.md §1.2, §3 =="
fail=0
[[ "$(read_state gate_statuses.G2)" == "pass" ]] && echo "✅ G2 build verified"  || { echo "❌ G2 not passed";                 fail=1; }
[[ "$(read_state gate_statuses.G3)" == "pass" ]] && echo "✅ G3 pilot verified"  || { echo "❌ G3 not passed";                 fail=1; }
cap="$(read_state spend.cap_usd)"
[[ -n "$cap" && "$cap" != "0" && "$cap" != "None" ]] && echo "✅ spend cap = \$$cap" || { echo "❌ no spend cap (set spend.cap_usd in .apsy/state.json)"; fail=1; }
irb="$(read_state irb_attested)"
[[ "$irb" =~ ^([Tt]rue|1)$ ]] && echo "✅ IRB approval/exemption attested" || { echo "❌ IRB not attested (confirm Cornell IRB, then: apsy-state.sh set irb_attested true)"; fail=1; }
[[ "${APSY_DEPLOY_APPROVED:-}" == "1" ]] && echo "✅ human approval token present" || { echo "❌ human approval token APSY_DEPLOY_APPROVED not set"; fail=1; }

if [[ $fail -ne 0 ]]; then
  echo; echo "💥 G4 NOT satisfied — deployment BLOCKED. Resolve the ❌ items; G4 is never auto-passed."
  exit 1
fi
echo "✅ G4 satisfied."

command -v psynet >/dev/null 2>&1 || { echo "❌ psynet not installed — cannot deploy. Run /apsy:doctor."; exit 3; }
app="${APSY_USERNAME:-user}.$(read_state label)"
echo "[apsy] deploy: backend=$backend app=$app (cap \$$cap)"
case "$backend" in
  ssh)    ( cd "$target" && psynet deploy ssh --app "$app" );;
  heroku) ( cd "$target" && psynet deploy heroku --app "$app" );;
  ec2)    echo "EC2 plan: dallinger ec2 provision --name $app --region ${APSY_AWS_REGION:-us-east-1} \\";
          echo "            --type ${APSY_EC2_TYPE:-m7i.xlarge} --dns ${app}.${APSY_BASE_DOMAIN:-DOMAIN}; then psynet deploy ssh --app $app";
          echo "⚠️  EC2 provisioning is finalized against a live runtime.";;
esac
printf '%s deploy backend=%s app=%s cap=$%s\n' "$(date -u +%FT%TZ)" "$backend" "$app" "$cap" >> "$target/.apsy/deployment-log.md"
echo "recorded to .apsy/deployment-log.md"
