#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): when touching experiment.py, inject the PsyNet code-gen gotchas.
# Non-blocking advisory. Reads the tool payload as JSON on stdin.
set -uo pipefail

payload="$(cat)"
fp="$(printf '%s' "$payload" | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))
except Exception:
    print("")' 2>/dev/null || true)"

case "$fp" in
  *experiment.py|*/trials.py|*/trial_maker.py|*/networks.py)
    cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"PsyNet gotchas — (1) every Page/PageMaker and every Trial subclass needs a time_estimate; (2) Module/TrialMaker id_ must be globally unique and never reuse the same object instance in a timeline; (3) every Control needs a bot_response or bot tests raise NotImplementedError; (4) static uses nodes=, chains use start_nodes= (list for 'across', lambda for 'within'); (5) use markupsafe.Markup for HTML prompts, put consent first; (6) emit experiment.py+config.txt+requirements.txt then run `psynet update-scripts`."}}
EOF
    ;;
esac
exit 0
