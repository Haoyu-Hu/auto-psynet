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

echo "== LLM-participant backend =="
if   [[ -n "${OPENAI_API_KEY:-}" ]];      then ok "OPENAI_API_KEY present (model: ${APSY_LLM_MODEL:-unset})"
elif [[ -n "${OPENROUTER_API_KEY:-}" ]];  then ok "OPENROUTER_API_KEY present (model: ${APSY_LLM_MODEL:-unset})"
elif [[ "${APSY_LLM_PROVIDER:-}" == "ambient" ]]; then ok "ambient Claude (subagents) configured"
else warn "no LLM-participant backend — run /apsy:setup (set a key or choose ambient Claude)"; fi

echo "== Dependencies (essential) =="
if have psynet; then ok "psynet CLI: $(psynet --version 2>/dev/null | head -1 || echo present)"; else bad "psynet not installed (pip install psynet)"; fi
psynet_path="$(python3 -c 'import psynet, os; print(os.path.dirname(psynet.__file__))' 2>/dev/null || true)"
[[ -n "$psynet_path" ]] && ok "psynet importable: $psynet_path  (recipes reference this install; record as APSY_PSYNET_PATH)" || warn "psynet not importable by python3"
have dallinger && ok "dallinger on PATH" || warn "dallinger not on PATH"
python3 -c "import pandas, scipy, statsmodels" 2>/dev/null && ok "python stats stack (pandas/scipy/statsmodels)" || warn "python stats stack incomplete (pip install pandas scipy statsmodels)"

echo "== PsyNet runtime (Docker/Postgres/Redis) =="
if have docker; then
  if docker info >/dev/null 2>&1; then ok "docker daemon reachable"; else warn "docker installed but daemon unreachable → use the ec2 backend"; fi
else warn "docker not installed → use the ec2 backend for server-side work"; fi
have pg_isready && { pg_isready >/dev/null 2>&1 && ok "postgres reachable" || warn "postgres not reachable (started by psynet/Docker at run time)"; } || warn "pg_isready not found (ok if using Docker)"
have redis-cli && { redis-cli ping >/dev/null 2>&1 && ok "redis reachable" || warn "redis not reachable (started by psynet/Docker at run time)"; } || warn "redis-cli not found (ok if using Docker)"

echo "== Deploy (EC2 / AWS) =="
if have aws; then
  if aws sts get-caller-identity >/dev/null 2>&1; then ok "AWS credentials valid (region ${APSY_AWS_REGION:-us-east-1})"; else warn "aws CLI present but credentials invalid/missing"; fi
else warn "aws CLI not installed (needed for the ec2 backend)"; fi
[[ -n "${APSY_BASE_DOMAIN:-}" ]] && ok "base domain: ${APSY_BASE_DOMAIN}" || warn "no base domain set (needed for ec2 DNS) — run /apsy:setup"

echo "== Config / identity =="
[[ -f "$APSY_CONFIG_FILE" ]] && ok "config: $APSY_CONFIG_FILE" || warn "no config — run /apsy:setup"
[[ -n "${APSY_USERNAME:-}" ]] && ok "username (server prefix): ${APSY_USERNAME}" || warn "no username set — run /apsy:setup"
