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

# Resolve the plugin root.
# Priority: CLAUDE_PLUGIN_ROOT (this is the Claude Code plugin) > CURSOR_PLUGIN_ROOT (the
# Cursor port at github.com/Haoyu-Hu/auto-psynet-cursor reuses the same bin/) > derive
# from this script's parent. The dual-env fallback lets the same bin/ work unchanged
# under both editors.
apsy_plugin_root() {
  echo "${CLAUDE_PLUGIN_ROOT:-${CURSOR_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
}

# apsy_resolve_python [override_path]
# Echoes the resolved Python interpreter on stdout. Returns non-zero if none is usable.
# Priority: override (--python) > $VIRTUAL_ENV/bin/python > $APSY_PYTHON > python3 from PATH.
apsy_resolve_python() {
  local override="${1:-}"
  apsy_load_config
  local py=""
  if [[ -n "$override" ]]; then
    py="$override"
  elif [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python" ]]; then
    py="${VIRTUAL_ENV}/bin/python"
  elif [[ -n "${APSY_PYTHON:-}" && -x "${APSY_PYTHON}" ]]; then
    py="$APSY_PYTHON"
  else
    py="$(command -v python3 || true)"
  fi
  [[ -z "$py" || ! -x "$py" ]] && return 1
  echo "$py"
}

# apsy_python_source [override_path] — describe how apsy_resolve_python picked the interpreter
# (informational; used for engine + doctor logging).
apsy_python_source() {
  local override="${1:-}"
  apsy_load_config
  if [[ -n "$override" ]]; then
    echo "--python override"
  elif [[ -n "${VIRTUAL_ENV:-}" && -x "${VIRTUAL_ENV}/bin/python" ]]; then
    echo "active VIRTUAL_ENV"
  elif [[ -n "${APSY_PYTHON:-}" && -x "${APSY_PYTHON}" ]]; then
    echo "APSY_PYTHON in $APSY_CONFIG_FILE"
  elif [[ -n "${APSY_PYTHON:-}" ]]; then
    echo "python3 (APSY_PYTHON=$APSY_PYTHON not executable; falling back)"
  else
    echo "python3 from PATH"
  fi
}
