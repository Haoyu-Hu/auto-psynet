#!/usr/bin/env bash
# apsy-install — install/pin/upgrade the essential dependencies (PsyNet + Dallinger; optionally the
# Python stats stack) into a chosen Python interpreter. Picks the interpreter via the resolver in
# apsy-common.sh: priority --python > $VIRTUAL_ENV > $APSY_PYTHON > python3 from PATH.
#
# Can optionally provision a managed virtualenv at ~/.auto-psynet/venv (or a custom path) on first
# run and record it as APSY_PYTHON in ~/.auto-psynet/config — that becomes the canonical "apsy
# python" for subsequent /apsy:install, /apsy:update, /apsy:doctor calls.
#
# Usage:
#   apsy-install.sh [--psynet VER|latest] [--dallinger VER|latest] [--stats] [--dry-run] [--upgrade]
#                   [--python PATH] [--create-venv] [--venv-path PATH]
#                   [--user | --no-user] [--break-system-packages]
#
# --upgrade           pip runs with --upgrade (used by /apsy:update); pre-install versions are
#                     captured and reported as "old → new" after install.
# --python PATH       use this interpreter (highest priority; doesn't record APSY_PYTHON).
# --create-venv       create a managed venv at ~/.auto-psynet/venv (or --venv-path PATH), record
#                     APSY_PYTHON, install into it.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"

psynet_ver=""; dallinger_ver=""; install_stats=0; dry_run=0; upgrade=0
python_override=""; create_venv=0; venv_path="$HOME/.auto-psynet/venv"
user_flag_explicit=""        # "", "--user", or "--no-user"
break_system=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --psynet)               shift; psynet_ver="${1:-}";    [[ -z "${1:-}" ]] && { echo "--psynet needs a value"; exit 2; } ;;
    --dallinger)            shift; dallinger_ver="${1:-}"; [[ -z "${1:-}" ]] && { echo "--dallinger needs a value"; exit 2; } ;;
    --stats)                install_stats=1 ;;
    --dry-run)              dry_run=1 ;;
    --upgrade)              upgrade=1 ;;
    --python)               shift; python_override="${1:-}"; [[ -z "${1:-}" ]] && { echo "--python needs a path"; exit 2; } ;;
    --create-venv)          create_venv=1 ;;
    --venv-path)            shift; venv_path="${1:-}"; [[ -z "${1:-}" ]] && { echo "--venv-path needs a path"; exit 2; } ;;
    --user)                 user_flag_explicit="--user" ;;
    --no-user)              user_flag_explicit="--no-user" ;;
    --break-system-packages) break_system=1 ;;
    --help|-h)
      cat <<'USAGE'
apsy-install — install/pin/upgrade PsyNet + Dallinger (and the Python stats stack).

Usage: apsy-install.sh [options]
  --psynet VER|latest         pin PsyNet version (default: latest)
  --dallinger VER|latest      pin Dallinger version (default: latest)
  --stats                     also install pandas/scipy/statsmodels if missing
  --dry-run                   resolve via 'pip install --dry-run'; do not install
  --upgrade                   pass pip's --upgrade flag (used by /apsy:update)
  --python PATH               use this Python interpreter (highest priority)
  --create-venv               provision a managed venv (default ~/.auto-psynet/venv); record APSY_PYTHON
  --venv-path PATH            custom venv path (only with --create-venv)
  --user | --no-user          force --user / no --user (default: auto-detect)
  --break-system-packages     pass pip's PEP-668 escape (only with explicit consent)

Interpreter priority (highest first):
  --python PATH  >  $VIRTUAL_ENV/bin/python  >  $APSY_PYTHON  >  python3 from PATH
USAGE
      exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

# --- Optional: provision a managed venv ------------------------------------
if [[ "$create_venv" -eq 1 ]]; then
  base_py="$(command -v python3 || true)"
  [[ -n "$base_py" ]] || { echo "❌ no python3 found in PATH; cannot create a venv"; exit 1; }
  if [[ -d "$venv_path" && -x "$venv_path/bin/python" ]]; then
    echo "[apsy-install] managed venv already present at $venv_path (reusing)"
  else
    echo "[apsy-install] creating managed venv at $venv_path (base: $base_py)"
    "$base_py" -m venv "$venv_path" || { echo "❌ venv creation failed"; exit 1; }
  fi
  venv_py="$venv_path/bin/python"
  [[ -x "$venv_py" ]] || { echo "❌ venv python not executable at $venv_py"; exit 1; }
  bash "$DIR/apsy-config.sh" set APSY_PYTHON "$venv_py" >/dev/null
  python_override="$venv_py"   # use the new venv for this run too
  echo "[apsy-install] recorded APSY_PYTHON=$venv_py in $HOME/.auto-psynet/config"
fi

# --- Resolve the interpreter ----------------------------------------------
PY="$(apsy_resolve_python "$python_override")" || { echo "❌ no usable python found"; exit 1; }
PY_SRC="$(apsy_python_source "$python_override")"

# --- Resolve --user --------------------------------------------------------
# A venv (active or APSY_PYTHON-managed) means we install INTO that venv → no --user.
in_venv=0
if   [[ -n "$python_override" ]]; then in_venv=1
elif [[ -n "${VIRTUAL_ENV:-}" ]];  then in_venv=1
elif [[ -n "${APSY_PYTHON:-}" && -x "${APSY_PYTHON}" ]]; then in_venv=1
fi

user_flag=""
if [[ "$user_flag_explicit" == "--user" ]]; then
  user_flag="--user"
elif [[ "$user_flag_explicit" == "--no-user" ]]; then
  user_flag=""
elif [[ "$in_venv" -eq 0 ]]; then
  # No venv → check writability of site-packages; fall back to --user if not.
  if "$PY" -c "import site,os,sys; p=site.getsitepackages()[0]; sys.exit(0 if os.access(p, os.W_OK) else 1)" 2>/dev/null; then
    user_flag=""
  else
    user_flag="--user"
  fi
fi

# --- Build the pip spec list ----------------------------------------------
specs=()
if [[ -n "$psynet_ver" && "$psynet_ver" != "latest" ]]; then specs+=("psynet==$psynet_ver"); else specs+=("psynet"); fi
if [[ -n "$dallinger_ver" && "$dallinger_ver" != "latest" ]]; then specs+=("dallinger==$dallinger_ver"); else specs+=("dallinger"); fi
[[ "$install_stats" -eq 1 ]] && specs+=("pandas" "scipy" "statsmodels")

# Capture pre-install versions so we can report "old → new" after an upgrade.
psv_old="$("$PY" -c 'import importlib.metadata as m; print(m.version("psynet"))' 2>/dev/null || echo "(not installed)")"
dlv_old="$("$PY" -c 'import importlib.metadata as m; print(m.version("dallinger"))' 2>/dev/null || echo "(not installed)")"

# Build the pip command as an array (handles empty optional flags safely under set -u).
cmd=("$PY" -m pip install)
[[ "$upgrade" -eq 1 ]]    && cmd+=("--upgrade")
[[ -n "$user_flag" ]]     && cmd+=("$user_flag")
[[ "$break_system" -eq 1 ]] && cmd+=("--break-system-packages")

echo "[apsy-install] python: $PY  ($PY_SRC)"
[[ -n "${VIRTUAL_ENV:-}" && "$in_venv" -eq 1 ]] && echo "[apsy-install] venv:   $VIRTUAL_ENV"
echo "[apsy-install] before: psynet=$psv_old   dallinger=$dlv_old"
echo "[apsy-install] plan:   ${cmd[*]} ${specs[*]}"

# --- Execute ---------------------------------------------------------------
if [[ "$dry_run" -eq 1 ]]; then
  echo "[apsy-install] DRY-RUN (pip --dry-run; no install)"
  "${cmd[@]}" --dry-run "${specs[@]}" 2>&1 | tail -40
  rc=${PIPESTATUS[0]}
  [[ $rc -eq 0 ]] && echo "✅ dry-run resolution succeeded" || echo "⚠️  dry-run resolution failed (rc=$rc)"
  exit "$rc"
fi

"${cmd[@]}" "${specs[@]}"
rc=$?
if [[ $rc -ne 0 ]]; then
  echo
  echo "❌ pip install failed (rc=$rc). Common fixes:"
  echo "   • use a managed venv: re-run with --create-venv"
  echo "   • point at your own venv/conda env: re-run with --python /path/to/python"
  echo "   • Debian/Ubuntu 'externally-managed': pass --break-system-packages (only if you understand the consequences)"
  echo "   • install build deps (gcc, postgresql-dev, libpq-dev)"
  exit "$rc"
fi

# --- Record versions + path -----------------------------------------------
psv="$("$PY" -c 'import importlib.metadata as m; print(m.version("psynet"))' 2>/dev/null || echo unknown)"
dlv="$("$PY" -c 'import importlib.metadata as m; print(m.version("dallinger"))' 2>/dev/null || echo unknown)"
psp="$("$PY" -c 'import psynet, os; print(os.path.dirname(psynet.__file__))' 2>/dev/null || true)"

bash "$DIR/apsy-config.sh" set APSY_PSYNET_VERSION    "$psv" >/dev/null
bash "$DIR/apsy-config.sh" set APSY_DALLINGER_VERSION "$dlv" >/dev/null
[[ -n "$psp" ]] && bash "$DIR/apsy-config.sh" set APSY_PSYNET_PATH "$psp" >/dev/null

echo
if [[ "$upgrade" -eq 1 ]]; then
  echo "✅ upgraded:"
  echo "   psynet     $psv_old → $psv"
  echo "   dallinger  $dlv_old → $dlv"
else
  echo "✅ installed:"
  echo "   psynet    $psv"
  echo "   dallinger $dlv"
fi
[[ -n "$psp" ]] && echo "   psynet path: $psp"
echo "   versions + path recorded in $HOME/.auto-psynet/config"
echo "   next: run /apsy:doctor to verify the full runtime (Docker/Postgres/Redis, LLM key, AWS, etc.)"
