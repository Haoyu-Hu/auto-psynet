#!/usr/bin/env bash
# apsy-doctor — environment diagnostics. Read-only; prints a status line per check. Never fails hard.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/apsy-common.sh"
apsy_load_config

ok()   { echo "✅ $1"; }
warn() { echo "⚠️  $1"; }
bad()  { echo "❌ $1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "== Python interpreter (apsy) =="
APSY_PY="$(apsy_resolve_python 2>/dev/null || true)"
APSY_PY_SRC="$(apsy_python_source)"
if [[ -n "$APSY_PY" ]]; then
  ok "apsy python: $APSY_PY  ($APSY_PY_SRC)"
  [[ -n "${APSY_PYTHON:-}" && "$APSY_PYTHON" != "$APSY_PY" ]] && \
    warn "APSY_PYTHON=$APSY_PYTHON is overridden by current resolution ($APSY_PY_SRC)"
else
  bad "no usable Python found (no --python, no \$VIRTUAL_ENV, no \$APSY_PYTHON, no python3 on PATH)"
fi
PY_CHECK="${APSY_PY:-python3}"

echo "== LLM-participant backend =="
if   [[ -n "${OPENAI_API_KEY:-}" ]];      then ok "OPENAI_API_KEY present (model: ${APSY_LLM_MODEL:-unset})"
elif [[ -n "${OPENROUTER_API_KEY:-}" ]];  then ok "OPENROUTER_API_KEY present (model: ${APSY_LLM_MODEL:-unset})"
elif [[ "${APSY_LLM_PROVIDER:-}" == "ambient" ]]; then ok "ambient Claude (subagents) configured"
else warn "no LLM-participant backend — run /apsy:setup (set a key or choose ambient Claude)"; fi

echo "== Dependencies (essential) =="
# Delegate to apsy-check.sh as the single source of truth for the dep/version status.
bash "$DIR/apsy-check.sh" | sed -n '/^dependencies:/,/^$/p' | sed '/^dependencies:/d;/^$/d'
# Surface the psynet path on a separate line for the "recipes use this install" note.
psynet_path="$("$PY_CHECK" -c 'import psynet, os; print(os.path.dirname(psynet.__file__))' 2>/dev/null || true)"
[[ -n "$psynet_path" ]] && ok "psynet path (recipes reference this): $psynet_path"
have psynet && ok "psynet CLI on PATH ($(psynet --version 2>/dev/null | head -1 || echo present))"

echo "== PsyNet runtime (Postgres + Redis required; Docker optional) =="
# Postgres + Redis are REQUIRED by `psynet debug local` even without Docker — psynet's _pre_launch
# calls redis_vars.clear() on the default Redis port before any of the debug paths branch, and the
# develop-mode server uses Postgres for the experiment DB. Verified 2026-05-28 against psynet 13.2.
have redis-cli && { redis-cli ping >/dev/null 2>&1 && ok "redis reachable on localhost:6379 (required for debug local)" || bad "redis-cli installed but Redis is DOWN (required for `psynet debug local` — start redis-server)"; } || bad "redis-cli not found — Redis is REQUIRED for `psynet debug local` (install via conda: \`conda install -c conda-forge redis-server\`)"
have pg_isready && { pg_isready >/dev/null 2>&1 && ok "postgres reachable on localhost:5432 (required for debug local; also need dallinger user + dallinger db)" || bad "pg_isready installed but Postgres is DOWN — start postgres + create the dallinger user/db"; } || bad "pg_isready not found — PostgreSQL is REQUIRED for \`psynet debug local\` (install via conda: \`conda install -c conda-forge postgresql\`)"
if have docker; then
  if docker info >/dev/null 2>&1; then ok "docker daemon reachable (optional; the --docker debug path uses it)"; else warn "docker installed but daemon unreachable (optional — debug local default path doesn't need it)"; fi
else warn "docker not installed (optional — only needed for --docker debug or real deploy via Dallinger)"; fi

echo "== Deploy (EC2 / AWS) =="
if have aws; then
  if aws sts get-caller-identity >/dev/null 2>&1; then ok "AWS credentials valid (region ${APSY_AWS_REGION:-us-east-1})"; else warn "aws CLI present but credentials invalid/missing"; fi
else warn "aws CLI not installed (needed for the ec2 backend)"; fi
[[ -n "${APSY_BASE_DOMAIN:-}" ]] && ok "base domain: ${APSY_BASE_DOMAIN}" || warn "no base domain set (needed for ec2 DNS) — run /apsy:setup"

echo "== Config / identity =="
[[ -f "$APSY_CONFIG_FILE" ]] && ok "config: $APSY_CONFIG_FILE" || warn "no config — run /apsy:setup"
[[ -n "${APSY_USERNAME:-}" ]] && ok "username (server prefix): ${APSY_USERNAME}" || warn "no username set — run /apsy:setup"
