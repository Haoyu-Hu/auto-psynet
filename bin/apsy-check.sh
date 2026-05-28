#!/usr/bin/env bash
# apsy-check — focused dependency + version check for the essential packages (psynet + dallinger +
# the Python stats stack). Runs against the resolved "apsy python" (apsy-common.sh:
# --python > $VIRTUAL_ENV > $APSY_PYTHON > python3 from PATH). Consumed by /apsy:setup STEP 2 and
# /apsy:doctor as a single source of truth for "are the essential deps OK?".
#
# Usage:
#   apsy-check.sh                  # deps only (no network)
#   apsy-check.sh --versions       # also: 'pip index versions' for PyPI latest (needs network)
#   apsy-check.sh --quiet          # one-line summary; exit code 1 if anything is missing
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"
apsy_load_config

check_versions=0; quiet=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --versions) check_versions=1 ;;
    --quiet)    quiet=1 ;;
    --help|-h)
      cat <<'USAGE'
apsy-check — dependency + version check (essential deps only).

Usage: apsy-check.sh [--versions] [--quiet]
  --versions   also fetch PyPI 'pip index versions' for psynet/dallinger (needs network)
  --quiet      one-line summary; exit 1 if any essential dep is missing
USAGE
      exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

PY="$(apsy_resolve_python 2>/dev/null || true)"
PY_SRC="$(apsy_python_source)"

pkg_version() {  # echoes installed version or empty
  local pkg="$1"
  [[ -z "$PY" ]] && return 0
  "$PY" -c "import importlib.metadata as m; print(m.version('$pkg'))" 2>/dev/null || true
}

pkg_latest() {   # echoes latest version on PyPI via 'pip index versions' (best-effort)
  local pkg="$1"
  [[ -z "$PY" ]] && return 0
  "$PY" -m pip index versions "$pkg" 2>/dev/null | head -1 | awk -F'[()]' '{print $2}' || true
}

missing=0; outdated=0; drifted=0
lines_dep=(); lines_ver=()

# --- Dependency check (always) --------------------------------------------
check_dep() {
  local pkg="$1" recorded_var="$2"
  local ver_installed ver_recorded line
  ver_installed="$(pkg_version "$pkg")"
  ver_recorded="${!recorded_var:-}"
  if [[ -n "$ver_installed" ]]; then
    line="  ✅ $pkg  $ver_installed"
    if [[ -n "$ver_recorded" && "$ver_recorded" != "$ver_installed" ]]; then
      line="$line  (config recorded $ver_recorded; drifted)"
      drifted=$((drifted+1))
    fi
  else
    line="  ❌ $pkg  not installed  → run /apsy:install"
    missing=$((missing+1))
  fi
  lines_dep+=("$line")
}

check_dep "psynet"    "APSY_PSYNET_VERSION"
check_dep "dallinger" "APSY_DALLINGER_VERSION"

# Stats stack — present-or-not (no version tracking)
if [[ -n "$PY" ]] && "$PY" -c "import pandas, scipy, statsmodels" 2>/dev/null; then
  lines_dep+=("  ✅ python stats stack (pandas, scipy, statsmodels)")
else
  lines_dep+=("  ❌ python stats stack (pandas, scipy, statsmodels) not importable  → run /apsy:install --stats")
  missing=$((missing+1))
fi

# --- Version comparison (optional; needs network) -------------------------
if [[ "$check_versions" -eq 1 ]]; then
  for pkg in psynet dallinger; do
    inst="$(pkg_version "$pkg")"
    if [[ -z "$inst" ]]; then continue; fi
    latest="$(pkg_latest "$pkg")"
    if [[ -z "$latest" ]]; then
      lines_ver+=("  ?  $pkg  installed $inst  latest unknown (PyPI unreachable?)")
    elif [[ "$inst" != "$latest" ]]; then
      lines_ver+=("  ⬆ $pkg  installed $inst  latest $latest  → /apsy:update")
      outdated=$((outdated+1))
    else
      lines_ver+=("  ✅ $pkg  installed $inst  latest $latest  (up to date)")
    fi
  done
fi

# --- Output ----------------------------------------------------------------
if [[ "$quiet" -eq 1 ]]; then
  if   [[ "$missing"  -gt 0 ]]; then echo "$missing missing"; exit 1
  elif [[ "$outdated" -gt 0 ]]; then echo "$outdated outdated"; exit 0
  elif [[ "$drifted"  -gt 0 ]]; then echo "$drifted drifted"; exit 0
  else echo "ok"; exit 0
  fi
fi

echo "== Auto-PsyNet dependency check =="
if [[ -n "$PY" ]]; then
  echo "apsy python: $PY  ($PY_SRC)"
else
  echo "❌ no usable python found (no --python, no \$VIRTUAL_ENV, no \$APSY_PYTHON, no python3 on PATH)"
  exit 1
fi
echo
echo "dependencies:"
printf '%s\n' "${lines_dep[@]}"

if [[ "$check_versions" -eq 1 && ${#lines_ver[@]} -gt 0 ]]; then
  echo
  echo "versions (PyPI):"
  printf '%s\n' "${lines_ver[@]}"
fi

echo
if   [[ "$missing"  -gt 0 ]]; then echo "summary: $missing essential dep(s) missing  → run /apsy:install"
elif [[ "$outdated" -gt 0 ]]; then echo "summary: $outdated package(s) outdated  → run /apsy:update"
elif [[ "$drifted"  -gt 0 ]]; then echo "summary: $drifted package(s) drifted from recorded version (no action required)"
else echo "summary: all essential dependencies present and current"
fi

[[ "$missing" -gt 0 ]] && exit 1
exit 0
