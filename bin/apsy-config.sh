#!/usr/bin/env bash
# apsy-config — get/set user-level config in ~/.auto-psynet/config (KEY=VALUE lines).
# Usage: apsy-config.sh set KEY VALUE   |   apsy-config.sh get [KEY]
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"

case "${1:-}" in
  set) apsy_set_config "${2:?key required}" "${3:?value required}"; echo "set $2=$3 in $APSY_CONFIG_FILE" ;;
  get) apsy_load_config
       if [[ -n "${2:-}" ]]; then echo "${!2:-}"; else [[ -f "$APSY_CONFIG_FILE" ]] && cat "$APSY_CONFIG_FILE" || echo "(no config yet)"; fi ;;
  *)   echo "usage: apsy-config.sh {set KEY VALUE | get [KEY]}"; exit 2 ;;
esac
