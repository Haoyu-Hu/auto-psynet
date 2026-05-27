#!/usr/bin/env bash
# apsy-state — locate / read the per-experiment .apsy state. Source of truth for resume.
set -uo pipefail

apsy_find() {
  local d="$PWD"
  while [[ "$d" != "/" && -n "$d" ]]; do
    [[ -d "$d/.apsy" ]] && { echo "$d/.apsy"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

cmd="${1:-}"
case "$cmd" in
  find)  apsy_find || { echo "NOT_FOUND"; exit 1; } ;;
  read)  s="$(apsy_find)" && [[ -f "$s/state.json" ]] && cat "$s/state.json" || { echo "NO_STATE"; exit 1; } ;;
  init)  # init <dir> — scaffold an .apsy/ from config/templates/
         root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
         dst="${2:-$PWD}/.apsy"
         mkdir -p "$dst"
         cp -n "$root/config/templates/"{state.json,research-plan.md,iteration-log.md,decisions.md,deployment-log.md} "$dst/" 2>/dev/null || true
         echo "$dst" ;;
  set)   # set <dotted.key> <value> — patch state.json in the nearest .apsy/
         s="$(apsy_find)" || { echo "NO_EXPERIMENT"; exit 1; }
         key="${2:-}"; val="${3:-}"
         [[ -z "$key" ]] && { echo "usage: apsy-state.sh set <dotted.key> <value>"; exit 2; }
         python3 - "$s/state.json" "$key" "$val" <<'PY'
import json, sys, datetime
path, key, val = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(path))
def coerce(v):
    for t in (int, float):
        try: return t(v)
        except ValueError: pass
    if v.lower() in ("true", "false"): return v.lower() == "true"
    return v
cur = d
parts = key.split(".")
for p in parts[:-1]:
    cur = cur.setdefault(p, {})
cur[parts[-1]] = coerce(val)
d["updated"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
json.dump(d, open(path, "w"), indent=2)
print(f"set {key}={val}")
PY
         ;;
  *)     echo "usage: apsy-state.sh {find|read|init [dir]|set <dotted.key> <value>}"; exit 2 ;;
esac
