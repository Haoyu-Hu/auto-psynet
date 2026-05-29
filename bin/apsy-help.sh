#!/usr/bin/env bash
# apsy-help — browse the /apsy:* command surface.
#
# Usage:
#   apsy-help.sh                # list every /apsy:* command + a one-line description
#   apsy-help.sh <name>         # show detailed help for one command
#   apsy-help.sh --search <q>   # list commands whose name or description matches the query
#
# Source of truth: the `description:` frontmatter field of each commands/<name>.md.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
COMMANDS_DIR="$ROOT/commands"

extract_description() {
  # Pull the `description:` line from a command's YAML frontmatter (handles multi-line via
  # tolerating only the first line; commands are expected to keep it terse).
  awk '
    /^---$/ { fm = !fm; next }
    fm && /^description:[[:space:]]/ {
      sub(/^description:[[:space:]]*/, "")
      print; exit
    }
  ' "$1"
}

short_desc() {
  # Trim description to <= 120 chars; collapse internal whitespace.
  local d="$1"
  d="$(echo "$d" | tr -s ' ')"
  if [[ ${#d} -gt 120 ]]; then echo "${d:0:117}..."; else echo "$d"; fi
}

list_all() {
  local pattern="${1:-}"
  echo "Auto-PsyNet (apsy) — command surface"
  echo "  (\`/apsy:help <name>\` for detailed help on any command)"
  echo
  for f in "$COMMANDS_DIR"/*.md; do
    local name desc
    name="$(basename "$f" .md)"
    desc="$(extract_description "$f")"
    if [[ -n "$pattern" ]]; then
      if [[ "$name" != *"$pattern"* && "${desc,,}" != *"${pattern,,}"* ]]; then continue; fi
    fi
    printf '  /apsy:%-14s  %s\n' "$name" "$(short_desc "$desc")"
  done | sort
  echo
}

show_one() {
  local name="$1"
  local f="$COMMANDS_DIR/$name.md"
  if [[ ! -f "$f" ]]; then
    echo "❌ no /apsy:$name command found."
    echo
    echo "Available commands:"
    for g in "$COMMANDS_DIR"/*.md; do
      printf '  /apsy:%s\n' "$(basename "$g" .md)"
    done | sort
    exit 1
  fi
  echo "/apsy:$name"
  echo "$(printf '%*s' "$((${#name}+7))" '' | tr ' ' '=')"
  cat "$f"
}

case "${1:-}" in
  ""|--list|-l) list_all "" ;;
  --search|-s) shift; list_all "${1:-}" ;;
  --help|-h) sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
  *) show_one "$1" ;;
esac
