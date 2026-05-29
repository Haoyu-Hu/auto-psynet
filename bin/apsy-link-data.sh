#!/usr/bin/env bash
# apsy-link-data — symlink ~/psynet-data → $APSY_PROJECT_DIR/data so PsyNet's hardcoded
# assets/launch-data/artifacts paths transparently land in the project tree. Engine for STEP 5
# of skills/project-dir/SKILL.md. Implements the 5-case safety table deterministically.
#
# Why: psynet hardcodes `~/psynet-data/assets`, `~/psynet-data/launch-data`,
# `~/psynet-data/artifacts` via os.path.expanduser (asset.py:2595, command_line.py:948,
# artifact.py:453). They're not env-var-driven or config-driven; the cleanest redirect is a HOME-
# level symlink.
#
# Usage:
#   apsy-link-data.sh                                 # defaults: target=~/psynet-data; dest=$APSY_PROJECT_DIR/data
#   apsy-link-data.sh --dest /path/to/data            # override destination
#   apsy-link-data.sh --target /alt/psynet-data       # override target (for testing)
#   apsy-link-data.sh --target X --dest Y             # both
#
# Exit codes:
#   0 = symlink in place (created OR was already correct)
#   2 = refused (wrong-symlink or real-dir-with-content) — user must resolve manually
#   3 = missing required input (no APSY_PROJECT_DIR and no --dest)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config

target=""
dest=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) shift; target="${1:-}"; [[ -z "$target" ]] && { echo "--target needs a value"; exit 2; } ;;
    --dest)   shift; dest="${1:-}";   [[ -z "$dest"   ]] && { echo "--dest needs a value";   exit 2; } ;;
    --help|-h)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac
  shift
done
target="${target:-$HOME/psynet-data}"
if [[ -z "$dest" ]]; then
  if [[ -n "${APSY_PROJECT_DIR:-}" ]]; then
    dest="${APSY_PROJECT_DIR}/data"
  else
    echo "❌ no destination — set APSY_PROJECT_DIR (via /apsy:project-dir) or pass --dest"; exit 3
  fi
fi
# Expand ~ in case it survived
target="${target/#\~/$HOME}"
dest="${dest/#\~/$HOME}"

echo "[apsy-link-data] target = $target"
echo "[apsy-link-data] dest   = $dest"

# --- Case detection ---
case_id=""
note=""
if [[ ! -e "$target" && ! -L "$target" ]]; then
  case_id="missing"
elif [[ -L "$target" ]]; then
  current="$(readlink -f "$target")"
  dest_canon="$(readlink -f "$dest" 2>/dev/null || echo "$dest")"
  if [[ "$current" == "$dest_canon" ]]; then
    case_id="already-correct"
  else
    case_id="symlink-elsewhere"
    note="$current"
  fi
elif [[ -d "$target" ]]; then
  if [[ -z "$(ls -A "$target" 2>/dev/null)" ]]; then
    case_id="empty-dir"
  else
    case_id="real-content"
  fi
else
  case_id="not-a-directory"
  note="$(file -b "$target" 2>/dev/null)"
fi

echo "[apsy-link-data] case   = $case_id"

# --- Act ---
case "$case_id" in
  missing)
    mkdir -p "$dest"
    ln -s "$dest" "$target"
    echo "[apsy-link-data] ✅ created symlink $target → $dest"
    exit 0 ;;

  empty-dir)
    rmdir "$target"
    mkdir -p "$dest"
    ln -s "$dest" "$target"
    echo "[apsy-link-data] ✅ removed empty $target; created symlink → $dest"
    exit 0 ;;

  already-correct)
    echo "[apsy-link-data] ✅ symlink already points at $dest (no-op)"
    exit 0 ;;

  symlink-elsewhere)
    echo "[apsy-link-data] ❌ REFUSED: $target is a symlink pointing at:"
    echo "                  $note"
    echo "                Expected destination:"
    echo "                  $dest"
    echo "                Resolve manually (rm + re-link, or keep the existing target)."
    exit 2 ;;

  real-content)
    echo "[apsy-link-data] ❌ REFUSED: $target is a real directory with content:"
    ls -la "$target" | head -10 | sed 's/^/                  /'
    echo "                Migration hint (run AT YOUR OWN RISK; reviews each step):"
    echo "                  mkdir -p '$dest'"
    echo "                  mv '$target'/* '$dest'/ 2>/dev/null || true"
    echo "                  mv '$target'/.[!.]* '$dest'/ 2>/dev/null || true"
    echo "                  rmdir '$target'"
    echo "                  ln -s '$dest' '$target'"
    exit 2 ;;

  not-a-directory)
    echo "[apsy-link-data] ❌ REFUSED: $target exists but is not a directory or symlink:"
    echo "                  $note"
    echo "                Move it aside before linking."
    exit 2 ;;
esac
