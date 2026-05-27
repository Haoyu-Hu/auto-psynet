---
name: doctor
description: "Diagnose the Auto-PsyNet runtime — use when the user says 'apsy doctor', 'check my setup', 'is everything working', or before first deploy. Validates Docker/Postgres/Redis, psynet, LLM keys, AWS, config, claude-mem."
---

# apsy:doctor — environment diagnostics

> EXECUTION CONTRACT. Runs the engine's check script and reports an actionable checklist. Read-only;
> never mutates the environment without explicit user consent.

## STEP 1 — Run checks
Resolve the plugin root (`${CLAUDE_PLUGIN_ROOT}`) and run `bin/apsy-doctor.sh`. It checks, and prints a
status line per item:
- `psynet` CLI installed + version; `dallinger` present
- Docker daemon reachable; Postgres reachable; Redis reachable
- LLM-participant backend: `OPENAI_API_KEY` / `OPENROUTER_API_KEY` present, **or** ambient-Claude mode
- AWS credentials present (for the `ec2` backend) + region
- `~/.auto-psynet/config` present and parseable
- claude-mem worker reachable (optional enrichment)

## STEP 2 — Report
Render results as a checklist using ✅ (ok) / ⚠️ (advisory) / ❌ (blocking). Group by: **LLM backend**,
**PsyNet runtime** (Docker/PG/Redis/psynet), **Deploy (EC2/AWS)**, **Config/Identity**, **Memory**.

## STEP 3 — Offer fixes
For each ❌/⚠️, give the concrete remedy (e.g. "no Docker → use the `ec2` backend, or install Docker";
"no LLM key → run `apsy:setup` and choose ambient Claude or set a key"; "no config → run `apsy:setup`").
Only run a fix after the user confirms. **Do not silently mutate the environment.**

## STEP 4 — Verdict
End with a one-line verdict: **green** (ready for local + LLM-pilot), **ec2-only** (no local Docker but
AWS ok), or **blocked** (what must be fixed first). Note that real human deployment additionally needs
the G4 gate (approval + IRB attestation + spend cap).
