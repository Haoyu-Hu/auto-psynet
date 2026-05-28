#!/usr/bin/env bash
# apsy-export — wrapper around `psynet export local` that redirects the output into
# $APSY_PROJECT_DIR/data/<study>/ instead of psynet's default `~/psynet-data/export/`.
#
# Why: psynet hardcodes export_root = "~/psynet-data/export" in psynet/experiment.py:1826. The
# CLI exposes `--path` to override per-call. This wrapper reads APSY_PROJECT_DIR + the current
# experiment label, computes the target path, and forwards everything to `psynet export local`.
#
# Falls through to plain `psynet export local` (psynet default = ~/psynet-data/export/) if
# APSY_PROJECT_DIR isn't set. Forwards any extra args (e.g. --no-source, --assets none).
#
# Usage:
#   bash bin/apsy-export.sh                 # current dir = experiment; redirect via APSY_PROJECT_DIR
#   bash bin/apsy-export.sh <psynet-args>   # forward extra args
#   bash bin/apsy-export.sh --path X        # explicit --path wins; APSY_PROJECT_DIR ignored
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config

# Resolve psynet binary via the apsy venv (consistent with apsy-debug.sh).
resolve_psynet_bin() {
  local py
  py="$(apsy_resolve_python 2>/dev/null || true)"
  if [[ -n "$py" ]]; then
    local bin_dir; bin_dir="$(dirname "$py")"
    [[ -x "$bin_dir/psynet" ]] && { echo "$bin_dir/psynet"; return; }
  fi
  command -v psynet 2>/dev/null
}

PSYNET_BIN="$(resolve_psynet_bin)"
if [[ -z "$PSYNET_BIN" ]]; then
  echo "⚠️  psynet not found in the resolved apsy python env. Run /apsy:install." >&2
  echo "    If you already have an export, point the analyze step at its data/ directly." >&2
  exit 3
fi
# PATH hygiene (same fix as apsy-debug.sh)
VENV_BIN="$(dirname "$PSYNET_BIN")"
case ":$PATH:" in *":$VENV_BIN:"*) ;; *) export PATH="$VENV_BIN:$PATH" ;; esac

# If the user explicitly passed --path, respect it (skip APSY_PROJECT_DIR rerouting).
explicit_path=0
for arg in "$@"; do
  [[ "$arg" == "--path" || "$arg" == --path=* ]] && explicit_path=1
done

# Resolve the experiment's label (for the data subdir name).
label=""
if [[ -f .apsy/state.json ]]; then
  label="$(python3 -c "import json; print(json.load(open('.apsy/state.json')).get('label') or '')" 2>/dev/null)"
fi
if [[ -z "$label" && -f experiment.py ]]; then
  label="$(grep -oE 'label\s*=\s*"[^"]+"' experiment.py | head -1 | sed -E 's/.*"([^"]+)"/\1/')"
fi
[[ -z "$label" ]] && label="$(basename "$PWD")"

# Compute the redirect target
extra_args=("$@")
if [[ "$explicit_path" -eq 0 && -n "${APSY_PROJECT_DIR:-}" ]]; then
  target_path="${APSY_PROJECT_DIR}/data/${label}"
  mkdir -p "$target_path"
  extra_args+=("--path" "$target_path")
  echo "[apsy-export] redirecting export → ${target_path}"
  echo "[apsy-export]   (APSY_PROJECT_DIR=${APSY_PROJECT_DIR}; label=${label})"
elif [[ "$explicit_path" -eq 1 ]]; then
  echo "[apsy-export] --path passed explicitly; honoring it (APSY_PROJECT_DIR ignored for this call)"
else
  echo "[apsy-export] APSY_PROJECT_DIR not set — using psynet default (~/psynet-data/export/)"
  echo "[apsy-export]   tip: \`/apsy:project-dir <path>\` redirects future exports under that root"
fi

echo "[apsy-export] running: $PSYNET_BIN export local ${extra_args[*]}"
exec "$PSYNET_BIN" export local "${extra_args[@]}"
