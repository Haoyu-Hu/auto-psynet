---
command: help
description: List every `/apsy:*` command with a one-line description, or print detailed help for one command (`/apsy:help <name>`). Also supports `/apsy:help --search <query>` to filter by keyword.
allowed-tools: Bash
---

# apsy:help — browse the command surface

The user-facing entry point for discovering and learning the plugin's commands. Reads the
`description:` frontmatter field of each `commands/*.md` (for the listing) and prints the full
file content (for the detail view) — so the help is always in sync with the actual commands.

## STEP 1 — Parse `$ARGUMENTS`
- **Empty** → list every command + one-line description.
- **A single word that matches a command file** (e.g. `debug`, `services`, `export`) → show that
  command's full help. Accept the `apsy:` prefix too (`apsy:debug` → `debug`).
- **`--search <query>`** (or `-s <query>`) → list commands whose name or description contains the
  query (case-insensitive).
- **`--help` / `-h`** → print the engine's own usage line.

## STEP 2 — Invoke the engine
Run `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-help.sh $ARGUMENTS` and relay output verbatim. The engine
handles all four cases above plus the "no such command" fallback (which lists the available names).

## STEP 3 — Light orchestration only
The engine's output is already well-formatted. Do **not** restructure, summarize, or augment it
beyond what the engine prints. The point of `/apsy:help` is a single authoritative answer about the
command surface — adding paraphrase from chat memory risks drift from the actual commands.

If the user asks a follow-up about a specific command after the listing (e.g. "what does
`/apsy:debug` do?"), re-invoke as `bash ${CLAUDE_PLUGIN_ROOT}/bin/apsy-help.sh debug` rather than
answering from memory.
