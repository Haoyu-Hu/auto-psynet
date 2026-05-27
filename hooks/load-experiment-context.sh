#!/usr/bin/env bash
# SessionStart hook: if cwd is (within) an Auto-PsyNet experiment, inject its state summary as context.
# Read-only. stdout from a SessionStart hook is added to the session context.
set -uo pipefail

dir="$PWD"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -d "$dir/.apsy" ]]; then
    echo "## Auto-PsyNet experiment context ($dir)"
    if [[ -f "$dir/.apsy/state.json" ]]; then
      echo "state.json:"
      cat "$dir/.apsy/state.json"
    fi
    if [[ -f "$dir/.apsy/iteration-log.md" ]]; then
      echo
      echo "Recent iteration-log:"
      tail -n 20 "$dir/.apsy/iteration-log.md"
    fi
    break
  fi
  dir="$(dirname "$dir")"
done
exit 0
