#!/usr/bin/env bash
# apsy-services — start/stop/status of Redis + PostgreSQL for `psynet debug local`.
#
# State dir: ${APSY_SERVICES_DIR:-$HOME/.auto-psynet/services}/
#   ├── redis/        ← Redis dump.rdb + redis.pid
#   └── pg/           ← Postgres data dir from initdb
#   pg.log           ← postgres log file
#
# Binary detection (in priority order):
#   1. APSY_REDIS_BIN / APSY_PG_CTL_BIN / APSY_INITDB_BIN / APSY_PSQL_BIN env overrides
#   2. PATH
#   3. Common conda paths (~/miniconda3/bin, ~/anaconda3/bin, /opt/conda/bin,
#      /opt/conda/envs/apsy-services/bin, and /tmp/apsy-services/bin for ad-hoc envs)
#
# Idempotent: start on already-running = no-op. Stop on already-stopped = no-op.
# Dallinger user + database are auto-created on first postgres start.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"; apsy_load_config

SERVICES_DIR="${APSY_SERVICES_DIR:-$HOME/.auto-psynet/services}"
REDIS_DIR="$SERVICES_DIR/redis"
PG_DIR="$SERVICES_DIR/pg"
PG_LOG="$SERVICES_DIR/pg.log"

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
PG_HOST="${PGHOST:-localhost}"
PG_PORT="${PGPORT:-5432}"

# --- Binary detection ----------------------------------------------------
find_binary() {
  local name="$1" env_var="$2"
  if [[ -n "${!env_var:-}" && -x "${!env_var}" ]]; then echo "${!env_var}"; return; fi
  local p; p="$(command -v "$name" 2>/dev/null || true)"
  [[ -n "$p" ]] && { echo "$p"; return; }
  for c in "$HOME/miniconda3/bin" "$HOME/anaconda3/bin" "/opt/conda/bin" \
           "/opt/conda/envs/apsy-services/bin" "/tmp/apsy-services/bin"; do
    [[ -x "$c/$name" ]] && { echo "$c/$name"; return; }
  done
  return 1
}

REDIS_SERVER="$(find_binary redis-server APSY_REDIS_BIN || true)"
REDIS_CLI="$(find_binary redis-cli APSY_REDIS_CLI_BIN || true)"
PG_INITDB="$(find_binary initdb APSY_INITDB_BIN || true)"
PG_CTL="$(find_binary pg_ctl APSY_PG_CTL_BIN || true)"
PG_ISREADY="$(find_binary pg_isready APSY_PG_ISREADY_BIN || true)"
PSQL="$(find_binary psql APSY_PSQL_BIN || true)"

INSTALL_HINT_REDIS="install: apt install redis-server (Ubuntu) · brew install redis (macOS) · conda install -c conda-forge redis-server (HPC fallback). pip/uv can't install it."
INSTALL_HINT_PG="install: apt install postgresql (Ubuntu) · brew install postgresql@14 (macOS) · conda install -c conda-forge postgresql (HPC fallback). pip/uv can't install it."

# --- State predicates ---------------------------------------------------
redis_running() {
  [[ -n "$REDIS_CLI" ]] && "$REDIS_CLI" -h "$REDIS_HOST" -p "$REDIS_PORT" ping >/dev/null 2>&1
}

pg_running() {
  [[ -n "$PG_ISREADY" ]] && "$PG_ISREADY" -h "$PG_HOST" -p "$PG_PORT" >/dev/null 2>&1
}

# --- Redis ops ----------------------------------------------------------
redis_start() {
  if redis_running; then
    echo "  ✅ redis already running on $REDIS_HOST:$REDIS_PORT"
    return 0
  fi
  if [[ -z "$REDIS_SERVER" ]]; then
    echo "  ❌ redis-server binary not found — $INSTALL_HINT_REDIS"
    return 1
  fi
  mkdir -p "$REDIS_DIR"
  "$REDIS_SERVER" --daemonize yes --port "$REDIS_PORT" --dir "$REDIS_DIR" \
                  --pidfile "$REDIS_DIR/redis.pid" >/dev/null 2>&1
  sleep 1
  if redis_running; then
    echo "  ✅ redis started on $REDIS_HOST:$REDIS_PORT  (data: $REDIS_DIR)"
  else
    echo "  ❌ redis start failed — check $REDIS_DIR/redis.pid + system log"
    return 1
  fi
}

redis_stop() {
  if ! redis_running; then
    echo "  (redis not running on $REDIS_HOST:$REDIS_PORT)"
    return 0
  fi
  "$REDIS_CLI" -h "$REDIS_HOST" -p "$REDIS_PORT" shutdown nosave 2>/dev/null || true
  sleep 1
  if redis_running; then
    echo "  ⚠️  redis still responding after shutdown command"
  else
    echo "  ✅ redis stopped"
  fi
}

# --- Postgres ops -------------------------------------------------------
pg_ensure_dallinger() {
  [[ -z "$PSQL" ]] && return 0
  pg_running || return 0
  local has_role has_db
  has_role=$("$PSQL" -U postgres -h "$PG_HOST" -p "$PG_PORT" -tAc \
              "SELECT 1 FROM pg_roles WHERE rolname='dallinger'" 2>/dev/null || echo "")
  if [[ "$has_role" != "1" ]]; then
    "$PSQL" -U postgres -h "$PG_HOST" -p "$PG_PORT" -c \
        "CREATE USER dallinger WITH PASSWORD 'dallinger' SUPERUSER" >/dev/null 2>&1 \
      && echo "  ✅ created dallinger superuser" || echo "  ⚠️  could not create dallinger user (may already exist)"
  fi
  has_db=$("$PSQL" -U postgres -h "$PG_HOST" -p "$PG_PORT" -tAc \
            "SELECT 1 FROM pg_database WHERE datname='dallinger'" 2>/dev/null || echo "")
  if [[ "$has_db" != "1" ]]; then
    "$PSQL" -U postgres -h "$PG_HOST" -p "$PG_PORT" -c \
        "CREATE DATABASE dallinger OWNER dallinger" >/dev/null 2>&1 \
      && echo "  ✅ created dallinger database" || echo "  ⚠️  could not create dallinger db"
  fi
}

pg_start() {
  if pg_running; then
    echo "  ✅ postgres already running on $PG_HOST:$PG_PORT"
    pg_ensure_dallinger
    return 0
  fi
  if [[ -z "$PG_CTL" ]]; then
    echo "  ❌ pg_ctl not found — $INSTALL_HINT_PG"
    return 1
  fi
  mkdir -p "$SERVICES_DIR"
  if [[ ! -f "$PG_DIR/PG_VERSION" ]]; then
    if [[ -z "$PG_INITDB" ]]; then
      echo "  ❌ initdb not found for first-time postgres setup"
      return 1
    fi
    echo "  initdb'ing $PG_DIR (first-time setup)..."
    "$PG_INITDB" -D "$PG_DIR" --auth=trust --username=postgres 2>&1 | tail -3 | sed 's/^/    /'
  fi
  "$PG_CTL" -D "$PG_DIR" -l "$PG_LOG" -o "-p $PG_PORT" start >/dev/null 2>&1
  sleep 2
  if pg_running; then
    echo "  ✅ postgres started on $PG_HOST:$PG_PORT  (data: $PG_DIR)"
    pg_ensure_dallinger
  else
    echo "  ❌ postgres start failed — tail of $PG_LOG:"
    tail -5 "$PG_LOG" 2>/dev/null | sed 's/^/     /'
    return 1
  fi
}

pg_stop() {
  if ! pg_running; then
    echo "  (postgres not running on $PG_HOST:$PG_PORT)"
    return 0
  fi
  if [[ -z "$PG_CTL" ]]; then
    echo "  ❌ pg_ctl not found — cannot stop cleanly. Use 'kill' or pkill postgres."
    return 1
  fi
  "$PG_CTL" -D "$PG_DIR" stop -m fast >/dev/null 2>&1
  sleep 1
  if pg_running; then
    echo "  ⚠️  postgres still up after stop command"
  else
    echo "  ✅ postgres stopped"
  fi
}

# --- Status -------------------------------------------------------------
show_status() {
  echo "  state dir:  $SERVICES_DIR"
  echo
  echo "  redis:"
  echo "    binary:   ${REDIS_SERVER:-❌ not found}"
  echo "    target:   $REDIS_HOST:$REDIS_PORT"
  if redis_running; then
    echo "    status:   ✅ running"
  else
    echo "    status:   ❌ stopped"
  fi
  echo
  echo "  postgres:"
  echo "    binary:   ${PG_CTL:-❌ not found (pg_ctl)}"
  echo "    target:   $PG_HOST:$PG_PORT"
  echo "    data:     $PG_DIR$([[ -f $PG_DIR/PG_VERSION ]] && echo "  (initdb'd)" || echo "  (not initdb'd)")"
  if pg_running; then
    echo "    status:   ✅ running"
    if [[ -n "$PSQL" ]]; then
      local has_db
      has_db=$("$PSQL" -U postgres -h "$PG_HOST" -p "$PG_PORT" -tAc \
                "SELECT 1 FROM pg_database WHERE datname='dallinger'" 2>/dev/null || echo "")
      if [[ "$has_db" == "1" ]]; then
        echo "    dallinger db: ✅ exists"
      else
        echo "    dallinger db: ❌ missing — run \`apsy-services.sh start\` to create"
      fi
    fi
  else
    echo "    status:   ❌ stopped"
  fi
}

# --- CLI dispatch -------------------------------------------------------
cmd="${1:-status}"
flag="${2:-}"

case "$cmd" in
  start)
    [[ "$flag" != "--pg-only"    ]] && redis_start
    [[ "$flag" != "--redis-only" ]] && pg_start
    ;;
  stop)
    [[ "$flag" != "--pg-only"    ]] && redis_stop
    [[ "$flag" != "--redis-only" ]] && pg_stop
    ;;
  status)
    show_status
    ;;
  restart)
    pg_stop; redis_stop
    sleep 1
    redis_start; pg_start
    ;;
  help|--help|-h)
    cat <<USAGE
apsy-services — start/stop/status for psynet debug local's runtime services.

Usage:
  apsy-services.sh [status]                   report what's running (default)
  apsy-services.sh start [--redis-only|--pg-only]
  apsy-services.sh stop  [--redis-only|--pg-only]
  apsy-services.sh restart
  apsy-services.sh help

Env overrides:
  APSY_SERVICES_DIR     state dir (default: ~/.auto-psynet/services)
  APSY_REDIS_BIN        path to redis-server
  APSY_PG_CTL_BIN       path to pg_ctl
  APSY_INITDB_BIN       path to initdb (first-time pg setup)
  APSY_PSQL_BIN         path to psql
  REDIS_HOST/REDIS_PORT/PGHOST/PGPORT  endpoint overrides
USAGE
    ;;
  *)
    echo "❌ unknown subcommand: $cmd  (try: status start stop restart help)"; exit 2 ;;
esac
