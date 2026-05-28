#!/usr/bin/env python3
"""apsy-add-recipe — add a new file under skills/psynet/psynet-function/ + update the parent index.

Stdlib only. Validates the recipe name (kebab/snake-case), refuses to overwrite by default, drops a
templated recipe skeleton (paradigm or cross-cutting), and inserts a row into the matching table of
skills/psynet/SKILL.md. The row format is identical to the existing rows so the index stays parseable.
"""
import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PSYNET_DIR = ROOT / "skills" / "psynet"
RECIPE_DIR = PSYNET_DIR / "psynet-function"
INDEX_FILE = PSYNET_DIR / "SKILL.md"

NAME_RE = re.compile(r"^[a-z][a-z0-9_-]{0,39}$")

PARADIGM_TMPL = """# Recipe: {title} (`{trial_maker}`)

**Archetype / domains:** TODO — list question-archetypes + domains this paradigm fits (see
`config/affinity.yaml`).

**When to use:** {purpose}. **Not** when ... TODO — fall back to ... TODO.

**PsyNet classes (subclass + override):**
- `MyTrial({trial_base})` — TODO key overrides (`show_trial`, `time_estimate`, ...).
- `MyTrialMaker({trial_maker})` — TODO key constructor args (`id_`, `nodes` / `start_nodes`, ...).

**bot_response:** TODO — how `Control.bot_response` is set so the LLM-participant driver can drive it.

**Gotchas:** TODO — 3–5 short bullets / inline phrases of common pitfalls.

**Worked example (installed psynet):** TODO — path under `APSY_PSYNET_PATH` (e.g.
`psynet/trial/{name_snake}.py` + `demos/experiments/{name_snake}/` when present).

**Data shape:** TODO — one-line per-trial CSV columns.

**Status:** planned — needs validation against the installed psynet package.
"""

CROSS_CUTTING_TMPL = """# Recipe: {title}

**Purpose:** {purpose}.

**When to use:** TODO — one paragraph criterion for picking this capability.

**PsyNet API:** TODO — relevant classes / functions / CLI commands (point to the installed psynet
package at `APSY_PSYNET_PATH`).

**Gotchas:** TODO — 3–5 short bullets / inline phrases.

**Worked example (installed psynet):** TODO — path under `APSY_PSYNET_PATH`.

**Status:** planned.
"""


def title_from_name(name):
    return " ".join(w.capitalize() for w in re.split(r"[-_]", name))


def trial_base_from_trial_maker(tm):
    """'StaticTrialMaker' → 'StaticTrial'; '<X>TrialMaker' → '<X>Trial'; unknown → keep."""
    if tm.endswith("TrialMaker"):
        return tm[: -len("Maker")]
    return tm


def build_content(name, category, purpose, trial_maker, source_file):
    if source_file:
        return pathlib.Path(source_file).read_text(encoding="utf-8")
    title = title_from_name(name)
    if category == "paradigm":
        return PARADIGM_TMPL.format(
            title=title,
            trial_maker=trial_maker or "TODO_TrialMaker",
            trial_base=trial_base_from_trial_maker(trial_maker) if trial_maker else "TODO_TrialBase",
            name_snake=name.replace("-", "_"),
            purpose=purpose,
        )
    return CROSS_CUTTING_TMPL.format(title=title, purpose=purpose)


def build_index_row(name, category, purpose, trial_maker):
    if category == "paradigm":
        return (
            f"| [`{name}.md`](psynet-function/{name}.md) "
            f"| `{trial_maker or 'TODO_TrialMaker'}` "
            f"| {purpose}. |"
        )
    return f"| [`{name}.md`](psynet-function/{name}.md) | {purpose}. |"


def update_index(name, category, purpose, trial_maker, write=True):
    """Insert a row into the matching table in skills/psynet/SKILL.md. Returns (changed, new_row)."""
    section_marker = (
        "## Paradigm recipes" if category == "paradigm" else "## Cross-cutting PsyNet functions"
    )
    new_row = build_index_row(name, category, purpose, trial_maker)
    text = INDEX_FILE.read_text(encoding="utf-8")
    lines = text.split("\n")

    i = next((k for k, line in enumerate(lines) if line.startswith(section_marker)), None)
    if i is None:
        raise SystemExit(f"could not find section '{section_marker}' in {INDEX_FILE}")
    # find first '|' line under the section
    j = i + 1
    while j < len(lines) and not lines[j].lstrip().startswith("|"):
        j += 1
    if j >= len(lines):
        raise SystemExit(f"no table found under '{section_marker}'")
    # walk to the last consecutive '|' line
    last = j
    while last + 1 < len(lines) and lines[last + 1].lstrip().startswith("|"):
        last += 1
    # idempotency: skip if a row for this name already exists in that table
    existing = "\n".join(lines[j : last + 1])
    if f"({name}.md)" in existing:
        return False, new_row

    lines.insert(last + 1, new_row)
    if write:
        INDEX_FILE.write_text("\n".join(lines), encoding="utf-8")
    return True, new_row


def main():
    ap = argparse.ArgumentParser(
        description="Add a new file under skills/psynet/psynet-function/ + update the parent index."
    )
    ap.add_argument("--name", required=True, help="kebab/snake-case recipe name (max 40 chars).")
    ap.add_argument("--category", required=True, choices=["paradigm", "cross-cutting"])
    ap.add_argument("--purpose", required=True, help="one-line description for index row + recipe top.")
    ap.add_argument("--trial-maker", default=None,
                    help="paradigm: TrialMaker class name (e.g. 'StaticTrialMaker').")
    ap.add_argument("--from", dest="source", default=None,
                    help="optional: copy from an existing .md instead of using the template.")
    ap.add_argument("--force", action="store_true", help="overwrite if file exists.")
    ap.add_argument("--dry-run", action="store_true",
                    help="show what would be written; do not touch disk.")
    args = ap.parse_args()

    if not NAME_RE.match(args.name):
        sys.exit(f"❌ invalid --name '{args.name}': must match {NAME_RE.pattern}")

    target = RECIPE_DIR / f"{args.name}.md"
    if target.exists() and not args.force:
        sys.exit(f"❌ {target} already exists. Pass --force to overwrite, or choose a different --name.")

    content = build_content(args.name, args.category, args.purpose, args.trial_maker, args.source)
    changed, new_row = update_index(
        args.name, args.category, args.purpose, args.trial_maker, write=False
    )

    if args.dry_run:
        print("[apsy-add-recipe] DRY-RUN — nothing written")
        print(f"  target file:  {target}")
        print(f"  category:     {args.category}")
        print(f"  index update: {'insert new row' if changed else 'row already present (skip)'}")
        print(f"  new row:      {new_row}")
        print("  --- file content ---")
        print(content)
        return 0

    target.write_text(content, encoding="utf-8")
    print(f"✅ wrote {target} ({len(content)} bytes)")
    if changed:
        # actually persist the index update
        update_index(args.name, args.category, args.purpose, args.trial_maker, write=True)
        print(f"✅ inserted row into {INDEX_FILE.relative_to(ROOT)}")
    else:
        print(f"   (row for '{args.name}' already in index — skipped insert)")
    print()
    print("next:")
    print(f"  1. edit {target.relative_to(ROOT)} — fill in TODO sections (classes, gotchas, worked-example path).")
    if args.category == "paradigm":
        print( "  2. add the paradigm id to config/affinity.yaml (which question-archetypes it serves).")
        print( "  3. validate: bash tests/validate-assembly.sh")
    else:
        print( "  2. validate: bash tests/validate-assembly.sh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
