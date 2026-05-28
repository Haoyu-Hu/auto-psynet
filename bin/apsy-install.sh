#!/usr/bin/env bash
# apsy-install — install/pin the essential dependencies (PsyNet + Dallinger; optionally the Python
# stats stack). Detects the active Python (venv vs system), prefers --user when site-packages aren't
# writable, never silently passes --break-system-packages. On success, records APSY_PSYNET_VERSION,
# APSY_DALLINGER_VERSION, and APSY_PSYNET_PATH into ~/.auto-psynet/config.
#
# Usage:
#   apsy-install.sh [--psynet VER|latest] [--dallinger VER|latest] [--stats] [--dry-run]
#                   [--user | --no-user] [--break-system-packages]
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"

psynet_ver=""; dallinger_ver=""; install_stats=0; dry_run=0
user_flag_explicit=""        # "", "--user", or "--no-user"
break_system=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --psynet)               shift; psynet_ver="${1:-}";    [[ -z "${1:-}" ]] && { echo "--psynet needs a value"; exit 2; } ;;
    --dallinger)            shift; dallinger_ver="${1:-}"; [[ -z "${1:-}" ]] && { echo "--dallinger needs a value"; exit 2; } ;;
    --stats)                install_stats=1 ;;
    --dry-run)              dry_run=1 ;;
    --user)                 user_flag_explicit="--user" ;;
    --no-user)              user_flag_explicit="--no-user" ;;
    --break-system-packages) break_system=1 ;;
    --help|-h)
      cat <<'USAGE'
apsy-install — install/pin PsyNet + Dallinger (and the Python stats stack).

Usage: apsy-install.sh [options]
  --psynet VER|latest         pin PsyNet version (default: latest)
  --dallinger VER|latest      pin Dallinger version (default: latest)
  --stats                     also install pandas/scipy/statsmodels if missing
  --dry-run                   resolve via 'pip install --dry-run'; do not install
  --user | --no-user          force --user / no --user (default: auto-detect)
  --break-system-packages     pass pip's PEP-668 escape (only with explicit consent)
USAGE
      exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac
  shift
done

PY="$(command -v python3 || true)"
[[ -n "$PY" ]] || { echo "❌ python3 not found in PATH"; exit 1; }

# --- Resolve --user --------------------------------------------------------
user_flag=""
if [[ "$user_flag_explicit" == "--user" ]]; then
  user_flag="--user"
elif [[ "$user_flag_explicit" == "--no-user" ]]; then
  user_flag=""
else
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    user_flag=""
  else
    # site-packages writable? → no --user; else --user
    if "$PY" -c "import site,os,sys; p=site.getsitepackages()[0]; sys.exit(0 if os.access(p, os.W_OK) else 1)" 2>/dev/null; then
      user_flag=""
    else
      user_flag="--user"
    fi
  fi
fi

# --- Build the pip spec list ----------------------------------------------
specs=()
if [[ -n "$psynet_ver" && "$psynet_ver" != "latest" ]]; then specs+=("psynet==$psynet_ver"); else specs+=("psynet"); fi
if [[ -n "$dallinger_ver" && "$dallinger_ver" != "latest" ]]; then specs+=("dallinger==$dallinger_ver"); else specs+=("dallinger"); fi
[[ "$install_stats" -eq 1 ]] && specs+=("pandas" "scipy" "statsmodels")

# Build the pip command as an array (handles empty optional flags safely under set -u).
cmd=("$PY" -m pip install)
[[ -n "$user_flag" ]] && cmd+=("$user_flag")
[[ "$break_system" -eq 1 ]] && cmd+=("--break-system-packages")

echo "[apsy-install] python: $PY"
[[ -n "${VIRTUAL_ENV:-}" ]] && echo "[apsy-install] venv:   $VIRTUAL_ENV"
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
  echo "   • use a virtualenv (python3 -m venv .venv && source .venv/bin/activate)"
  echo "   • pass --user (re-run with --user) if you don't want to use a venv"
  echo "   • Debian/Ubuntu 'externally-managed': pass --break-system-packages (only if you understand the consequences)"
  echo "   • install build deps (gcc, postgresql-dev, libpq-dev)"
  exit "$rc"
fi

# --- Record versions + path -----------------------------------------------
psv="$("$PY" -c 'import psynet; print(getattr(psynet, "__version__", "unknown"))' 2>/dev/null || echo unknown)"
dlv="$("$PY" -c 'import dallinger; print(getattr(dallinger, "__version__", "unknown"))' 2>/dev/null || echo unknown)"
psp="$("$PY" -c 'import psynet, os; print(os.path.dirname(psynet.__file__))' 2>/dev/null || true)"

bash "$DIR/apsy-config.sh" set APSY_PSYNET_VERSION    "$psv" >/dev/null
bash "$DIR/apsy-config.sh" set APSY_DALLINGER_VERSION "$dlv" >/dev/null
[[ -n "$psp" ]] && bash "$DIR/apsy-config.sh" set APSY_PSYNET_PATH "$psp" >/dev/null

echo
echo "✅ installed:"
echo "   psynet    $psv"
echo "   dallinger $dlv"
[[ -n "$psp" ]] && echo "   psynet path: $psp"
echo "   versions + path recorded in $HOME/.auto-psynet/config"
echo "   next: run /apsy:doctor to verify the full runtime (Docker/Postgres/Redis, LLM key, AWS, etc.)"
