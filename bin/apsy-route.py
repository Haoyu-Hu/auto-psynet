#!/usr/bin/env python3
"""apsy-route — deterministic rule-based router for /apsy:auto.

Reads `config/routing.json` and, when available, the nearest `.apsy/state.json`. Given a free-text query,
scores each `/apsy:*` intent by keyword matches (+ a small priority tie-breaker) and a stage-aware boost
(the current pipeline stage's next-action intent gets a bump). Emits JSON with the recommendation,
confidence (high / medium / low), and the top candidates + reasons. Stdlib only.

Usage:  apsy-route.py <query>  [--state path/to/state.json]
Output: JSON on stdout.
"""
import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def load_config():
    p = ROOT / "config" / "routing.json"
    return json.loads(p.read_text(encoding="utf-8"))


def find_state():
    d = pathlib.Path.cwd().resolve()
    while True:
        cand = d / ".apsy" / "state.json"
        if cand.is_file():
            return cand
        if d.parent == d:
            return None
        d = d.parent


def score(query, cfg, state):
    q = (query or "").lower().strip()
    scores, reasons = {}, {}
    next_action = (cfg.get("stage_next_action", {}) or {}).get(
        (state or {}).get("stage") if isinstance(state, dict) else None
    )
    for name, intent in cfg["intents"].items():
        s = 0.0
        r = []
        for kw in intent.get("keywords", []):
            if kw and kw.lower() in q:
                s += 2.0
                r.append(f"matched '{kw}'")
        s += 0.05 * intent.get("priority", 0)
        if next_action == name:
            s += float(cfg.get("stage_boost", 4.0))
            r.append(f"stage next-action boost (stage={(state or {}).get('stage')})")
        scores[name] = s
        reasons[name] = r
    return scores, reasons


def decide(scores, cfg):
    ordered = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
    top = ordered[0] if ordered else (None, 0.0)
    second = ordered[1] if len(ordered) > 1 else (None, 0.0)
    high = float(cfg.get("high_min_score", 4.0))
    margin = float(cfg.get("high_min_margin", 1.5))
    medium = float(cfg.get("medium_min_score", 2.0))
    if top[1] >= high and (top[1] - second[1]) >= margin:
        conf = "high"
    elif top[1] >= medium:
        conf = "medium"
    else:
        conf = "low"
    return conf, ordered


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("query", nargs="?", default="")
    ap.add_argument("--state", default=None, help="path to a state.json (else searched from cwd)")
    a = ap.parse_args()

    cfg = load_config()
    state = None
    sp = pathlib.Path(a.state) if a.state else find_state()
    if sp and sp.is_file():
        try:
            state = json.loads(sp.read_text(encoding="utf-8"))
        except Exception:
            state = None

    scores, reasons = score(a.query, cfg, state)
    conf, ordered = decide(scores, cfg)
    top3 = [
        {
            "intent": n,
            "command": cfg["intents"][n]["command"],
            "score": round(s, 2),
            "reasons": reasons[n],
        }
        for n, s in ordered[:3]
    ]
    out = {
        "query": a.query,
        "stage": (state or {}).get("stage") if isinstance(state, dict) else None,
        "confidence": conf,
        "recommended_intent": ordered[0][0] if ordered else None,
        "recommended_command": cfg["intents"][ordered[0][0]]["command"] if ordered else None,
        "top": top3,
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
