#!/usr/bin/env bash
# Shared helpers for the apsy engine. Source it:  . "$(dirname "${BASH_SOURCE[0]}")/apsy-common.sh"
set -uo pipefail

APSY_CONFIG_DIR="${APSY_CONFIG_DIR:-$HOME/.auto-psynet}"
APSY_CONFIG_FILE="$APSY_CONFIG_DIR/config"

apsy_ensure_config_dir() { mkdir -p "$APSY_CONFIG_DIR"; }

# Load ~/.auto-psynet/config (KEY=VALUE lines) into the environment.
apsy_load_config() {
  if [[ -f "$APSY_CONFIG_FILE" ]]; then
    set -a; . "$APSY_CONFIG_FILE"; set +a
  fi
}

# apsy_set_config KEY VALUE  — idempotent upsert into the config file.
apsy_set_config() {
  local k="$1" v="$2"
  apsy_ensure_config_dir
  touch "$APSY_CONFIG_FILE"
  if grep -q "^${k}=" "$APSY_CONFIG_FILE" 2>/dev/null; then
    sed -i.bak "s|^${k}=.*|${k}=${v}|" "$APSY_CONFIG_FILE" && rm -f "$APSY_CONFIG_FILE.bak"
  else
    echo "${k}=${v}" >> "$APSY_CONFIG_FILE"
  fi
}

# Resolve the plugin root (prefer the Claude Code env var; fall back to this script's parent).
apsy_plugin_root() {
  echo "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
}
