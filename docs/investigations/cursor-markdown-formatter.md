# Investigation: unexpected Markdown rewrites (2026-04-17)

## What happened

While working on unrelated docs, two tracked files were rewritten without an explicit request:

| File | Observed change |
|------|-----------------|
| `docs/product/feature-parity-checklist.md` | **Data loss:** GitHub-flavored task-list markers (`- [ ]` / `- [x]`) were stripped, blank lines inserted — treated as destructive; **not** committed; working tree restored from `HEAD`. |
| `docs/design/design.md` | **Benign:** extra blank lines between blocks; trailing newline at EOF was inconsistent — normalized to a single POSIX trailing newline while keeping the spacing edits. |

A stash was captured before the ADR bootstrap commit (`pre-adr formatter residue`) so the diffs could be inspected without blocking that PR.

## Repo scan (invariants)

- No committed [Prettier](https://prettier.io/) config, no `.editorconfig`, no `.vscode/` or `.cursor/rules` Markdown format settings in-tree.
- Checkbox stripping is **not** default Prettier Markdown behavior (Prettier generally preserves list markers).

## `.cursor/` contents (this workspace)

At investigation time, the only tracked-path-adjacent artifact under `.cursor/` was:

- `hooks/state/continual-learning.json` — hook/session bookkeeping for Cursor; **no** `settings.json`, **no** formatter configuration.

That supports the hypothesis that formatting came from the **Cursor IDE** (or an installed VS Code–compatible Markdown extension) acting on save or on paste, not from a repo-local config file.

## Likely cause (hypothesis)

- **Markdown format-on-save** in the editor, or a Markdown extension that normalizes lists / blank lines / EOF.
- Task-list checkbox removal specifically points at a **GFM-oriented** or “clean up document” transform, not generic whitespace — worth disabling or scoping per-workspace if it recurs.

## Mitigations applied

- `.gitignore` entries for `.cursor/` and `.claude/` so local editor/agent state does not appear as untracked noise or get committed by mistake.
- This note for future readers and for CI/review if the pattern reappears.

## Follow-ups (optional)

- Add a workspace `.vscode/settings.json` **only if** the team agrees to commit editor defaults; otherwise document “disable Markdown format on save for this repo” in `CONTRIBUTING.md`.
- If `project.yml` is removed per `docs/ENGINEERING_STANDARD.md`, ensure CI does not depend on a formatter touching Markdown.
