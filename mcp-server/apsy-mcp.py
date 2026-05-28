#!/usr/bin/env python3
"""apsy MCP server — minimal stdlib stdio JSON-RPC bridge over the Auto-PsyNet engine.

Every tool is a **thin wrapper** around an existing `bin/apsy-*.{sh,py}` helper — no engine logic is
duplicated here. Stdlib only (`json`, `subprocess`, `sys`); no extra deps beyond what the plugin already
needs. Opt-in: the server exits immediately unless `APSY_MCP_ENABLED=true`.

Protocol: newline-delimited JSON-RPC 2.0 on stdio (MCP stdio transport, protocolVersion 2024-11-05).
Methods supported: `initialize`, `initialized` (notification), `tools/list`, `tools/call`, `ping`,
`shutdown`. Unknown methods return JSON-RPC error -32601.
"""
import json
import os
import pathlib
import subprocess
import sys
import traceback

PROTOCOL_VERSION = "2024-11-05"
SERVER_NAME = "apsy"
SERVER_VERSION = "0.0.1"
ROOT = pathlib.Path(__file__).resolve().parent.parent


def log(msg):
    sys.stderr.write(f"[apsy-mcp] {msg}\n"); sys.stderr.flush()


def call_engine(args, timeout=120):
    """Run a bin/apsy-* helper and return (stdout+stderr, exit_code)."""
    try:
        p = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
        out = p.stdout
        if p.returncode != 0 and p.stderr:
            out += "\n[stderr]\n" + p.stderr
        return out, p.returncode
    except subprocess.TimeoutExpired:
        return f"timeout after {timeout}s", 124
    except Exception as e:
        return f"engine call failed: {e}", 1


# ---------------------------------------------------------------- Tools

TOOLS = [
    {"name": "apsy_status",
     "description": "Read the current Auto-PsyNet experiment state (the nearest .apsy/state.json from cwd) — stage, gate_statuses, next_action, spend, etc.",
     "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
    {"name": "apsy_doctor",
     "description": "Run environment diagnostics — essential deps (psynet, dallinger, stats stack), Docker/Postgres/Redis, LLM key, AWS, config.",
     "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}},
    {"name": "apsy_route",
     "description": "Route a natural-language intent to the right /apsy:* command (deterministic rules + current-stage boost).",
     "inputSchema": {"type": "object",
                     "properties": {"query": {"type": "string", "description": "free-text intent"}},
                     "required": ["query"], "additionalProperties": False}},
    {"name": "apsy_next",
     "description": "Compute the next action in the autonomous pipeline given the current state.json + autonomy_level.",
     "inputSchema": {"type": "object",
                     "properties": {"with_deployment": {"type": "boolean", "default": False}},
                     "additionalProperties": False}},
    {"name": "apsy_power",
     "description": "Compute required sample size for a planned design (t2 / paired / corr / prop2 / anova).",
     "inputSchema": {"type": "object",
                     "properties": {
                         "test": {"type": "string", "enum": ["t2", "paired", "corr", "prop2", "anova"]},
                         "effect": {"type": "number"},
                         "alpha":  {"type": "number", "default": 0.05},
                         "power":  {"type": "number", "default": 0.8},
                         "p1":     {"type": "number"},
                         "groups": {"type": "integer"}},
                     "required": ["test", "effect"], "additionalProperties": False}},
    {"name": "apsy_data_quality",
     "description": "Screen a data export for completion, exclusions, duplicates, attention checks, target-N.",
     "inputSchema": {"type": "object",
                     "properties": {
                         "path":     {"type": "string", "description": "export directory or participant CSV"},
                         "target_n": {"type": "integer"}},
                     "required": ["path"], "additionalProperties": False}},
]


# Tool handlers — every one just delegates to bin/apsy-*.

def _find_state_dir():
    d = pathlib.Path.cwd().resolve()
    while True:
        if (d / ".apsy" / "state.json").is_file():
            return d
        if d.parent == d:
            return None
        d = d.parent


def h_status(a):
    sd = _find_state_dir()
    return (sd / ".apsy" / "state.json").read_text(encoding="utf-8") if sd \
        else "no .apsy/state.json found; run /apsy:idea to scaffold an experiment."

def h_doctor(a):     return call_engine(["bash", str(ROOT / "bin" / "apsy-doctor.sh")])[0]
def h_route(a):
    q = (a.get("query") or "").strip()
    if not q: return "error: 'query' is required"
    return call_engine(["python3", str(ROOT / "bin" / "apsy-route.py"), q])[0]
def h_next(a):
    args = ["python3", str(ROOT / "bin" / "apsy-run.py"), "next"]
    if a.get("with_deployment"): args.append("--with-deployment")
    return call_engine(args)[0]
def h_power(a):
    args = ["python3", str(ROOT / "bin" / "apsy-power.py"),
            "--test", a["test"], "--effect", str(a["effect"])]
    for k in ("alpha", "power", "p1"):
        if k in a: args += [f"--{k}", str(a[k])]
    if "groups" in a: args += ["--groups", str(a["groups"])]
    return call_engine(args)[0]
def h_data_quality(a):
    args = ["python3", str(ROOT / "bin" / "apsy-data-quality.py"), a["path"]]
    if "target_n" in a: args += ["--target-n", str(a["target_n"])]
    return call_engine(args)[0]

DISPATCH = {
    "apsy_status": h_status, "apsy_doctor": h_doctor, "apsy_route": h_route,
    "apsy_next": h_next, "apsy_power": h_power, "apsy_data_quality": h_data_quality,
}


# ---------------------------------------------------------------- JSON-RPC

def send(msg):
    sys.stdout.write(json.dumps(msg) + "\n"); sys.stdout.flush()

def err(req_id, code, message):
    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}}

def result(req_id, data):
    return {"jsonrpc": "2.0", "id": req_id, "result": data}


def handle(req):
    m = req.get("method"); rid = req.get("id"); params = req.get("params") or {}
    if m == "initialize":
        return result(rid, {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
        })
    if m in ("initialized", "notifications/initialized"):
        return None  # notifications: no response
    if m == "ping":
        return result(rid, {})
    if m == "tools/list":
        return result(rid, {"tools": TOOLS})
    if m == "tools/call":
        name = params.get("name"); args = params.get("arguments") or {}
        fn = DISPATCH.get(name)
        if not fn:
            return err(rid, -32601, f"unknown tool: {name}")
        try:
            text = fn(args)
        except Exception as e:
            return result(rid, {
                "content": [{"type": "text", "text": f"error: {e}\n{traceback.format_exc()}"}],
                "isError": True,
            })
        return result(rid, {"content": [{"type": "text", "text": text}], "isError": False})
    if m == "shutdown":
        return result(rid, None)
    return err(rid, -32601, f"method not found: {m}")


def main():
    if os.environ.get("APSY_MCP_ENABLED", "").lower() not in ("1", "true", "yes"):
        log("APSY_MCP_ENABLED not set — exiting (server is opt-in). "
            "Set APSY_MCP_ENABLED=true to run.")
        sys.exit(0)
    log(f"{SERVER_NAME} MCP server ({SERVER_VERSION}) ready on stdio; plugin root = {ROOT}")
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except Exception as e:
            send(err(None, -32700, f"parse error: {e}"))
            continue
        try:
            resp = handle(req)
        except Exception as e:
            resp = err(req.get("id"), -32603, f"internal: {e}")
        if resp is not None:
            send(resp)
        if req.get("method") == "shutdown":
            log("shutdown received; exiting")
            return
    log("stdin EOF; exiting")


if __name__ == "__main__":
    main()
