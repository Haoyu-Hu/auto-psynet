# Plugin name is LOCKED to `apsy`

The plugin name **`apsy`** is load-bearing and must not change casually:

- It is the **slash-command namespace** — every command is invoked as `/apsy:<command>`.
- It must be **identical** in `.claude-plugin/plugin.json` (`name`) and the `plugins[]` entry of
  `.claude-plugin/marketplace.json`. A mismatch breaks installation.
- It appears in hooks, docs, and user muscle memory.

The npm/repo name is intentionally **different**: repo **`auto-psynet`** vs plugin call name **`apsy`**
(decision D2 in `project-plan/05-roadmap.md`).

`tests/validate-assembly.sh` enforces that both manifests agree on `apsy`.

**If you ever must rename:** update both manifests, every `/apsy:*` reference across `commands/`,
`skills/`, `hooks/`, `README.md`, and `project-plan/`, the assembly test, then bump the version.
