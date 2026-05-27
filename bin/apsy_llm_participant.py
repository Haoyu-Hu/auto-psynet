#!/usr/bin/env python3
"""Auto-PsyNet LLM-participant driver.

Routes PsyNet bot responses through an LLM so an experiment can be piloted with LLM-agent participants
(architecture §3.6). It monkeypatches `Control.call__get_bot_response` so that, when APSY_LLM_PILOT=1,
each control's answer is produced by an LLM conditioned on the page prompt + the control's affordances —
otherwise behavior is unchanged (the deterministic bot_response used for G2 tests).

Backend: OpenAI or OpenRouter (/v1/chat/completions, bearer key — same shape the lab's vibe_coding
experiment uses), selected via APSY_LLM_PROVIDER / APSY_LLM_MODEL / OPENAI_API_KEY / OPENROUTER_API_KEY.
If no external key is set, piloting should instead be driven by the ambient Claude orchestrator (the
llm-pilot skill handles that path); this module raises so the caller can fall back.

The pure helpers (serialize_page, describe_affordances, parse_answer, _range_of) are importable and
testable WITHOUT psynet. The psynet integration (llm_bot_response, enable) imports psynet lazily and is
verified against a live runtime.

CLI:  python apsy_llm_participant.py --dry-run
"""
import json
import os
import re
import sys
import urllib.request

OPENAI_URL = "https://api.openai.com/v1/chat/completions"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


def _cfg():
    return {
        "provider": os.environ.get("APSY_LLM_PROVIDER", "openai"),
        "model": os.environ.get("APSY_LLM_MODEL", "gpt-4o"),
        "openai_key": os.environ.get("OPENAI_API_KEY", ""),
        "openrouter_key": os.environ.get("OPENROUTER_API_KEY", ""),
    }


# --------------------------------------------------------------------------- pure helpers
def _range_of(md):
    """Return (lo, hi) if the control metadata describes a numeric range, else None."""
    pairs = [("min", "max"), ("min_value", "max_value"), ("start", "end"), ("lower", "upper")]
    for lo, hi in pairs:
        if lo in md and hi in md:
            try:
                return float(md[lo]), float(md[hi])
            except (TypeError, ValueError):
                pass
    return None


def describe_affordances(control_type, md):
    md = md or {}
    if "choices" in md:
        opts = "; ".join(f'"{c}"' for c in md["choices"])
        return f"Choose exactly ONE option from: {opts}\nReply with only the chosen option text, nothing else."
    rng = _range_of(md)
    if rng:
        lo, hi = rng
        return f"Respond with a number between {lo:g} and {hi:g}.\nReply with only the number."
    return "Respond with a short free-text answer.\nReply with only your answer."


def serialize_page(prompt_text, control_type, control_metadata, persona=None):
    lines = []
    if persona:
        lines.append(persona.strip())
        lines.append("")
    lines.append("You are shown the following in an online experiment:")
    lines.append((prompt_text or "(no prompt text)").strip())
    lines.append("")
    lines.append(describe_affordances(control_type, control_metadata))
    return "\n".join(lines)


def parse_answer(text, control_type, control_metadata):
    """Coerce free LLM text into the control's answer space; deterministic fallback on failure."""
    md = control_metadata or {}
    t = (text or "").strip()
    if "choices" in md:
        choices = md["choices"]
        for c in choices:                                   # exact (case-insensitive)
            if t.lower() == str(c).lower():
                return c
        for c in choices:                                   # substring either direction
            cl = str(c).lower()
            if cl and (cl in t.lower() or t.lower() in cl):
                return c
        return choices[0]                                   # fallback (caller logs)
    rng = _range_of(md)
    if rng:
        lo, hi = rng
        m = re.search(r"-?\d+(?:\.\d+)?", t)
        if m:
            return max(lo, min(hi, float(m.group())))
        return (lo + hi) / 2
    return t                                                # free text


# --------------------------------------------------------------------------- LLM call
def llm_complete(system, user, cfg=None):
    cfg = cfg or _cfg()
    if cfg["provider"] == "ambient" or (not cfg["openai_key"] and not cfg["openrouter_key"]):
        raise RuntimeError(
            "no external LLM key configured — pilot via the ambient Claude orchestrator "
            "(the llm-pilot skill) or set a key with apsy:setup"
        )
    if cfg["provider"] == "openrouter" and cfg["openrouter_key"]:
        url, key = OPENROUTER_URL, cfg["openrouter_key"]
    else:
        url, key = OPENAI_URL, cfg["openai_key"]
    body = json.dumps({
        "model": cfg["model"],
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "temperature": 1.0,
    }).encode()
    req = urllib.request.Request(url, data=body, method="POST", headers={
        "Authorization": f"Bearer {key}", "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.load(r)
    return data["choices"][0]["message"]["content"]


# --------------------------------------------------------------------------- psynet integration (lazy import)
def _prompt_text(prompt):
    for attr in ("text", "plain_text"):
        v = getattr(prompt, attr, None)
        if isinstance(v, str) and v.strip():
            return v
    try:
        md = prompt.metadata() if callable(getattr(prompt, "metadata", None)) else getattr(prompt, "metadata", None)
        if isinstance(md, dict) and md.get("text"):
            return str(md["text"])
    except Exception:
        pass
    return str(prompt)


def _control_metadata(control):
    try:
        md = control.metadata
        return md() if callable(md) else md
    except Exception:
        return {}


def llm_bot_response(experiment, bot, page, prompt, control, persona=None):
    from psynet.bot import BotResponse
    ctype = type(control).__name__
    md = _control_metadata(control)
    user = serialize_page(_prompt_text(prompt), ctype, md, persona)
    system = ("You are simulating a single human participant in a behavioral experiment. "
              "Respond as a plausible participant would, honestly and in the exact format requested, "
              "with no explanation or extra words.")
    text = llm_complete(system, user)
    answer = parse_answer(text, ctype, md)
    return BotResponse(raw_answer=answer, metadata={"apsy_llm": True, "llm_raw": text})


def enable(persona=None):
    """Monkeypatch Control dispatch so APSY_LLM_PILOT=1 routes responses through the LLM. Idempotent.
    Falls back to the original (deterministic) behavior if the LLM errors, so pilots degrade gracefully."""
    from psynet import modular_page as mp
    Control = mp.Control
    if getattr(Control, "_apsy_patched", False):
        return
    original = Control.call__get_bot_response

    def patched(self, experiment, bot, page, prompt):
        if os.environ.get("APSY_LLM_PILOT") == "1":
            try:
                return llm_bot_response(experiment, bot, page, prompt, self, persona)
            except Exception as e:  # noqa: BLE001 — never crash a pilot on one LLM hiccup
                sys.stderr.write(f"[apsy] LLM participant fell back to default response ({e})\n")
        return original(self, experiment, bot, page, prompt)

    Control.call__get_bot_response = patched
    Control._apsy_patched = True


# --------------------------------------------------------------------------- CLI dry-run (no psynet, no API)
def _dry_run():
    print("=== option control ===")
    md = {"choices": ["Not at all", "Somewhat", "Very much"],
          "labels": ["Not at all", "Somewhat", "Very much"]}
    print(serialize_page("How pleasant is this sound?", "PushButtonControl", md,
                         "You are a participant who tends to find consonant sounds pleasant."))
    for s in ["Very much", "i'd say somewhat", "totally unparseable"]:
        print(f"  parse({s!r:30}) -> {parse_answer(s, 'PushButtonControl', md)!r}")
    print("\n=== slider control ===")
    md2 = {"min": 0, "max": 100}
    print(serialize_page("Rate the loudness.", "SliderControl", md2))
    for s in ["72", "about 50ish", "no idea"]:
        print(f"  parse({s!r:30}) -> {parse_answer(s, 'SliderControl', md2)!r}")
    print("\n=== free text ===")
    print(f"  parse({'  a banana '!r}) -> {parse_answer('  a banana ', 'TextControl', {})!r}")


if __name__ == "__main__":
    if "--dry-run" in sys.argv:
        _dry_run()
    else:
        print("usage: apsy_llm_participant.py --dry-run   "
              "(or `import apsy_llm_participant; apsy_llm_participant.enable()` inside a psynet pilot)")
