#!/usr/bin/env bash
# SessionStart hook: nudge /apsy:setup on first run, when the user hasn't configured the plugin yet.
# Emits an additionalContext message (informational only — does NOT auto-run anything). Fires only
# when ~/.auto-psynet/config does NOT exist, so once the user has set up the plugin the hook is silent
# forever.
set -uo pipefail

if [[ -f "$HOME/.auto-psynet/config" ]]; then
  exit 0
fi

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Auto-PsyNet is loaded but not configured (no ~/.auto-psynet/config). **Start with `/apsy:setup`** — it (1) picks the Python interpreter and optionally creates a managed venv at ~/.auto-psynet/venv, (2) runs the dependency + version check (`bin/apsy-check.sh`), (3) offers `/apsy:install` if psynet/dallinger/stats-stack are missing, (4) configures the LLM-participant backend, username, AWS region, base domain, and consent default. Other /apsy:* commands assume setup is complete."}}
EOF
exit 0
