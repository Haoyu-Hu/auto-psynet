# apsy MCP server — optional

A thin, **opt-in** MCP server that exposes Auto-PsyNet engine tools over the MCP stdio protocol —
useful from non-Claude clients (Cursor, Codex, custom automation) or as a scriptable alternative entry
to the same helpers the Claude Code skills already call.

- **Stdlib-only Python.** No extra dependencies beyond what the plugin already needs.
- **Opt-in.** The server exits immediately unless `APSY_MCP_ENABLED=true` is set.
- **Thin wrapper.** Every tool delegates to an existing `bin/apsy-*` helper; no engine logic is
  duplicated here.

## Tools exposed

| Tool | Wraps | Purpose |
|------|------|---------|
| `apsy_status` | `.apsy/state.json` | Current experiment stage, gate statuses, next action. |
| `apsy_doctor` | `bin/apsy-doctor.sh` | Environment diagnostics (deps, runtime, LLM key, AWS, config). |
| `apsy_route` | `bin/apsy-route.py` | NL → `/apsy:*` deterministic routing (incl. stage boost). |
| `apsy_next` | `bin/apsy-run.py next` | Autonomous-pipeline next action + autonomy decision. |
| `apsy_power` | `bin/apsy-power.py` | Required sample size for t2 / paired / corr / prop2 / anova. |
| `apsy_data_quality` | `bin/apsy-data-quality.py` | Completion / exclusion / target-N screen on an export. |

## Wire it into a client

### Claude Code (`~/.claude/mcp.json` or per-project `.mcp.json`)
```json
{
  "mcpServers": {
    "apsy": {
      "command": "python3",
      "args": ["/absolute/path/to/auto-psynet/mcp-server/apsy-mcp.py"],
      "env": { "APSY_MCP_ENABLED": "true" }
    }
  }
}
```

### Cursor / other MCP clients
Same shape — point the client at `python3 mcp-server/apsy-mcp.py` with `APSY_MCP_ENABLED=true` in env.

## Smoke-test from a shell
```bash
APSY_MCP_ENABLED=true python3 mcp-server/apsy-mcp.py <<'JSON'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"apsy_route","arguments":{"query":"diagnose dependencies"}}}
JSON
```
You should see three JSON responses on stdout (initialize → tools list → routed command).

## Security notes
- Opt-in (`APSY_MCP_ENABLED`) by design — non-Claude clients won't pick the server up by accident.
- The server only invokes the plugin's own `bin/apsy-*` helpers; it does not eval arbitrary input or
  fetch from the network beyond what those helpers already do (e.g. `apsy:literature-ground`'s search,
  which still runs via the skill side, not this server).
- No secrets are accepted via arguments; all keys come from environment / `~/.auto-psynet/config`.
