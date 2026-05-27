#!/usr/bin/env bash
# Auto-PsyNet plugin assembly validation — manifests, name lock, dirs, frontmatter, scripts, config.
# Exits non-zero on any failure. Run: bash tests/validate-assembly.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail=0
err(){ echo "❌ $1"; fail=1; }
ok(){ echo "✅ $1"; }

echo "== Manifests (valid JSON) =="
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json config/templates/state.json; do
  if python3 -c "import json;json.load(open('$f'))" 2>/dev/null; then ok "$f"; else err "invalid/missing JSON: $f"; fi
done

echo "== Plugin name lock (apsy) =="
pn=$(python3 -c "import json;print(json.load(open('.claude-plugin/plugin.json'))['name'])" 2>/dev/null || echo "")
mn=$(python3 -c "import json;print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['name'])" 2>/dev/null || echo "")
if [[ "$pn" == "apsy" && "$mn" == "apsy" ]]; then ok "name locked to 'apsy' in both manifests"; else err "name mismatch: plugin='$pn' marketplace='$mn' (expected apsy)"; fi

echo "== Required directories =="
for d in commands skills agents hooks bin config config/templates config/gates config/domains config/blind-spots skills/psynet skills/psynet/psynet-function; do
  [[ -d "$d" ]] && ok "$d/" || err "missing dir: $d/"
done

echo "== Command frontmatter =="
for f in commands/*.md; do
  if grep -q '^command:' "$f" && grep -q '^description:' "$f"; then ok "$f"; else err "missing command/description: $f"; fi
done

echo "== Skill frontmatter =="
for f in skills/*/SKILL.md; do
  if grep -q '^name:' "$f" && grep -q '^description:' "$f"; then ok "$f"; else err "missing name/description: $f"; fi
done

echo "== Agent frontmatter =="
for f in agents/*.md; do
  if grep -q '^name:' "$f" && grep -q '^description:' "$f"; then ok "$f"; else err "missing name/description: $f"; fi
done

echo "== Hook scripts (exist + executable) =="
for h in load-experiment-context psynet-lint spend-gate; do
  s="hooks/$h.sh"
  if [[ ! -f "$s" ]]; then err "missing hook: $s"; elif [[ -x "$s" ]]; then ok "$s"; else err "not executable: $s"; fi
done

echo "== Engine scripts (exist + executable) =="
for b in apsy-common apsy-doctor apsy-state apsy-debug; do
  s="bin/$b.sh"
  if [[ ! -f "$s" ]]; then err "missing engine: $s"; elif [[ -x "$s" ]]; then ok "$s"; else err "not executable: $s"; fi
done

echo "== Required config =="
for f in config/ethics-policy.md config/pipeline.yaml config/affinity.yaml config/gates/G1.yaml config/gates/G4.yaml skills/psynet/SKILL.md skills/psynet/psynet-function/static.md skills/psynet/psynet-function/gsp.md; do
  [[ -f "$f" ]] && ok "$f" || err "missing config: $f"
done

echo
if [[ "$fail" -eq 0 ]]; then echo "🎉 assembly OK"; else echo "💥 assembly FAILED"; fi
exit "$fail"
