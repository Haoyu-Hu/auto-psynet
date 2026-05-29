#!/usr/bin/env bash
# apsy-debug — run the current experiment for debugging. Targets: local | ec2.
# Debug only; does NOT enable real recruitment (that is /apsy:deploy, gated by G4).
#
# For `local`, runs `psynet debug local` (the default --no-docker auto-reload path) after running
# pre-flight checks + auto-fixing the easy ones:
#   - .gitignore (create with standard PsyNet patterns if missing)
#   - `git init` + an initial commit (if not a git repo)
#   - constraints.txt (generate via `psynet generate-constraints` if missing)
#   - PATH: ensure the apsy venv's bin/ is FIRST (otherwise `flask` resolves to the wrong interp)
#   - Redis + PostgreSQL reachable (warn loudly if not — `psynet debug local` needs both natively)
#   - experiment.py config sanity (recruiter, dashboard_password) — warn, don't block
#
# Lifecycle reminder: PsyNet experiments have NO stop signal. `Ctrl+C` in THIS terminal is the only
# way to kill the server. Before Ctrl+C, run `psynet export local` in a separate shell to capture
# any data.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config

target="${1:-local}"

resolve_psynet_bin() {
  # Prefer the apsy-resolved python's bin/psynet so we don't accidentally use a different psynet.
  local py
  py="$(apsy_resolve_python 2>/dev/null || true)"
  if [[ -n "$py" ]]; then
    local bin_dir
    bin_dir="$(dirname "$py")"
    if [[ -x "$bin_dir/psynet" ]]; then
      echo "$bin_dir/psynet"
      return 0
    fi
  fi
  command -v psynet 2>/dev/null
}

case "$target" in
  local)
    echo "[apsy-debug] target = local → psynet debug local (default --no-docker auto-reload path)"

    # --- 0. Resolve psynet bin + put its venv on PATH front ---
    PSYNET_BIN="$(resolve_psynet_bin)"
    if [[ -z "$PSYNET_BIN" ]]; then
      echo "❌ psynet not installed in the resolved apsy python env. Run /apsy:install."
      exit 1
    fi
    VENV_BIN="$(dirname "$PSYNET_BIN")"
    case ":$PATH:" in
      *":$VENV_BIN:"*) ;;  # already on PATH
      *) export PATH="$VENV_BIN:$PATH" ;;
    esac
    echo "[apsy-debug] python venv: $VENV_BIN"

    # --- 1. Auto-fix: .gitignore ---
    if [[ ! -f .gitignore ]]; then
      cat > .gitignore <<'GI'
# PsyNet experiment .gitignore — required by `psynet debug local` pre-checks.
data/
export/
*.zip
__pycache__/
*.pyc
*.pyo
.pytest_cache/
server.log
logs.jsonl
source_code.zip
# Auto-PsyNet additions: synthetic pilot data + locale catalog scratch
.apsy/pilot/data/
.apsy/analysis/__pycache__/
GI
      echo "[apsy-debug] auto-fix: wrote .gitignore"
    fi

    # --- 2. Auto-fix: git init + initial commit ---
    if [[ ! -d .git ]]; then
      git init -q . 2>/dev/null
      git -c user.email=apsy-debug@local -c user.name=apsy-debug add -A 2>/dev/null
      git -c user.email=apsy-debug@local -c user.name=apsy-debug commit -q -m "apsy-debug initial commit" 2>/dev/null || true
      echo "[apsy-debug] auto-fix: git init + initial commit"
    fi

    # --- 3. Auto-fix: constraints.txt via psynet generate-constraints ---
    if [[ ! -f constraints.txt ]]; then
      echo "[apsy-debug] auto-fix: generating constraints.txt via \`psynet generate-constraints\`..."
      "$PSYNET_BIN" generate-constraints 2>&1 | tail -3
      [[ -f constraints.txt ]] && echo "[apsy-debug] ✅ constraints.txt ($(wc -c < constraints.txt) bytes)" || echo "[apsy-debug] ⚠️  generate-constraints did not produce constraints.txt"
    fi

    # --- 4. Check: Redis + Postgres reachable (required even for non-Docker debug) ---
    miss=0
    if command -v redis-cli >/dev/null 2>&1; then
      if redis-cli -h "${REDIS_HOST:-localhost}" -p "${REDIS_PORT:-6379}" ping >/dev/null 2>&1; then
        echo "[apsy-debug] ✅ redis reachable on ${REDIS_HOST:-localhost}:${REDIS_PORT:-6379}"
      else
        echo "[apsy-debug] ❌ Redis is NOT reachable (psynet _pre_launch calls redis on all 3 debug paths)"
        echo "                easy fix: bash $DIR/apsy-services.sh start"
        echo "                or manually: redis-server --daemonize yes"
        miss=1
      fi
    else
      echo "[apsy-debug] ❌ redis-cli not found — Redis is REQUIRED for \`psynet debug local\`"
      echo "                install (in priority order):"
      echo "                  • Debian/Ubuntu:  sudo apt install redis-server"
      echo "                  • macOS:          brew install redis"
      echo "                  • RHEL/Fedora:    sudo dnf install redis"
      echo "                  • no-root/HPC:    conda install -c conda-forge redis-server  (fallback)"
      echo "                (pip/uv can't install Redis — it's not a Python package)"
      miss=1
    fi
    if command -v pg_isready >/dev/null 2>&1; then
      if pg_isready -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" >/dev/null 2>&1; then
        echo "[apsy-debug] ✅ postgres reachable on ${PGHOST:-localhost}:${PGPORT:-5432}"
      else
        echo "[apsy-debug] ❌ Postgres is NOT reachable (dallinger uses it for the experiment DB)"
        echo "                easy fix: bash $DIR/apsy-services.sh start  (handles initdb + dallinger user/db automatically)"
        echo "                or manually: pg_ctl -D <data> start  + create dallinger user + db"
        miss=1
      fi
    else
      echo "[apsy-debug] ❌ pg_isready not found — PostgreSQL is REQUIRED for \`psynet debug local\`"
      echo "                install (in priority order):"
      echo "                  • Debian/Ubuntu:  sudo apt install postgresql"
      echo "                  • macOS:          brew install postgresql@14"
      echo "                  • RHEL/Fedora:    sudo dnf install postgresql-server"
      echo "                  • no-root/HPC:    conda install -c conda-forge postgresql  (fallback)"
      echo "                (pip/uv can't install Postgres — it's not a Python package)"
      miss=1
    fi
    if [[ "$miss" -eq 1 ]]; then
      echo
      echo "❌ Pre-launch services not ready."
      echo "   One-command fix: bash $DIR/apsy-services.sh start"
      echo "     (detects redis-server + pg_ctl on PATH or common conda paths; initdb's the pg"
      echo "     data dir on first run; auto-creates the dallinger user + database; idempotent"
      echo "     on already-running.)"
      echo "   For per-OS install hints see skills/psynet/psynet-function/cli-and-deployment.md."
      exit 2
    fi

    # --- 5. Soft-check: experiment.py config sanity ---
    if [[ -f experiment.py ]]; then
      if grep -q '"recruiter":\s*"prolific"\|"recruiter":\s*"mturk"\|"recruiter":\s*"lucid' experiment.py; then
        echo "[apsy-debug] ⚠️  experiment.py uses a panel recruiter (prolific/lucid/mturk)."
        echo "                Local debug will return HTTP 500 at /launch unless the panel"
        echo "                workspace is configured. Switch to recruiter='generic' for debug."
      fi
      if ! grep -q "dashboard_password" experiment.py; then
        echo "[apsy-debug] ⚠️  no dashboard_password in experiment.py — \`psynet export local\` will"
        echo "                fail with KeyError. Add it to Exp.config (see config/templates/)."
      fi
    fi

    # --- 6. Lifecycle reminder (the user's stated workflow) ---
    cat <<'LIFE'

────────────────────────────────────────────────────────────────────────────────
  RUNTIME LIFECYCLE — read this before you launch.
  • PsyNet experiments have NO stop signal. The server runs INDEFINITELY.
  • Ctrl+C in THIS terminal is the only way to kill it.
  • Before Ctrl+C: in a SEPARATE shell, run  bash bin/apsy-export.sh
    (the wrapper passes --path APSY_PROJECT_DIR/data/<study> when project-dir is set;
    otherwise it falls through to psynet's default ~/psynet-data/export/<study>__...).
    Verify the export contents, THEN come back here and Ctrl+C to destroy.
  • Hot-reload (werkzeug stat reloader) fires on every edit, but workers stay STALE
    after class-structure changes — RESTART is required for:
      - the top-level Exp class (config dict, label, attributes)
      - any TrialMaker subclass
      - module-level imported classes used by the timeline
    (Edits to method bodies / literals / comments / bot_response / time_estimate
    values usually hot-reload cleanly.)
────────────────────────────────────────────────────────────────────────────────

LIFE

    # --- 7. Launch ---
    echo "[apsy-debug] launching: $PSYNET_BIN debug local"
    exec "$PSYNET_BIN" debug local
    ;;

  ec2)
    # Phase-1 wiring. Provisions/refreshes a Dallinger EC2 instance, then debugs over SSH.
    region="${APSY_AWS_REGION:-us-east-1}"
    echo "[apsy] debug target = ec2 (region ${region})"
    echo "Planned: dallinger ec2 provision --name ${APSY_USERNAME:-USER}.<study> \\"
    echo "           --region ${region} --type m7i.<N>xlarge --dns <study>.${APSY_BASE_DOMAIN:-DOMAIN}"
    echo "         then psynet debug ssh --app <study> (recruitment OFF)."
    echo "⚠️  EC2 wiring is implemented in Phase 1; this is the documented plan for now."
    exit 0
    ;;

  *)
    echo "usage: apsy-debug.sh {local|ec2}"
    exit 2
    ;;
esac
