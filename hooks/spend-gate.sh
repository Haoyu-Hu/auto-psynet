#!/usr/bin/env bash
# PreToolUse (Bash): HARD-GATE real deployment/recruitment (G4). Debug + LLM-pilot are NOT gated.
# Blocks `psynet deploy` / `dallinger deploy` (which enable recruitment = real spend) unless the G4 gate
# has been satisfied and APSY_DEPLOY_APPROVED=1 is set. Fails open on parse error to avoid breaking the
# session (Phase 2 hardens this).
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("command",""))
except Exception:
    print("")' 2>/dev/null || true)"

# Real-spend triggers: the deploy command (it turns on the recruiter), or explicit recruiter open/publish.
if printf '%s' "$cmd" | grep -Eiq '(psynet|dallinger)[[:space:]]+deploy|recruiter[[:space:]]+(open|publish)'; then
  if [[ "${APSY_DEPLOY_APPROVED:-}" == "1" ]]; then
    exit 0
  fi
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"G4 HARD GATE: real deployment/recruitment requires explicit human approval + an IRB attestation + a configured spend cap (see config/ethics-policy.md). Use /apsy:deploy to run the G4 gate; it sets APSY_DEPLOY_APPROVED=1 only after approval. Local debug and LLM-pilot are not gated."}}
EOF
  exit 0
fi
exit 0
