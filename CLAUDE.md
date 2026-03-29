# Lumen Repository Instructions

Lumen is a **privacy-first, local-first, Apple-native AI assistant** being built as both a serious App Store product and a portfolio-quality showcase.

This repository should read like it is maintained by disciplined senior engineers. Avoid noisy, amateurish, or sprawling work.

## Source of Truth
Before making broad product decisions, consult:
- `docs/PRD.md`
- `docs/DESIGN.md`
- `docs/ROADMAP.md`
- `docs/micro-prds/`

If there is tension between convenience and product coherence, prefer the documented product/design direction.

## Core Product Rules
- Preserve Lumen's identity: **privacy-first, local-first, Apple-native, opinionated**.
- Do **not** port Enchanted features wholesale. Port maturity and proven patterns only when they fit Lumen.
- Prefer native Apple frameworks and modern SwiftUI / iOS APIs over custom hacks.
- App Store readiness, trust, accessibility, and permission recovery are product features, not cleanup.

## Code Change Philosophy
- One logical change per commit.
- One concern per PR.
- Small, reviewer-friendly diffs.
- Architecture and core abstractions before polish.
- Fail fast on risky work. Save easy wins for later.
- Avoid over-engineering and unrelated cleanup in focused tasks.
- Delete dead code fully; do not leave commented-out remnants or backwards-compatibility hacks unless explicitly required.

Ask after each change: **Would a strong senior Apple engineer consider this overcomplicated, hacky, or noisy?** If yes, simplify.

## Lumen-Specific Engineering Principles
### Native first
- Use `safeAreaInset`, `GlassEffectContainer`, `tabBarMinimizeBehavior`, `tabViewBottomAccessory`, and other platform-native APIs where appropriate.
- Avoid forcing layouts with brittle hard-coded offsets when SwiftUI has a native layout model for it.

### Clear boundaries
- App shell owns navigation and chrome.
- Chat layer owns message rendering and input orchestration.
- Stores own state, not ad hoc UI logic.
- Services own reusable integrations and provider-specific behavior.
- Shared architecture work should be carefully scoped and not mixed with cosmetic work.

### Product polish matters
The following count as engineering-critical work:
- accessibility
- permission-denied recovery UX
- privacy clarity
- export/backup trust features
- release confidence and smoke tests
- support/public product documentation

## Workflow Rules
- Branch per task.
- Draft PRs first when work is not yet fully validated.
- Keep upstream-facing work clean and intentional.
- Do not create noisy or premature upstream PRs.
- Fork-first / review-first discipline applies for substantial work.
- Shared shell/navigation/settings/provider work should have a single owner or tightly controlled sequencing.

## Parallel Agent Rules
- Follow the micro-PRD structure.
- Parallelize only isolated tasks.
- Do not run multiple agents against the same shell/settings/provider files unless the task is explicitly coordinated.
- If a task reveals architectural uncertainty, stop and document it instead of papering over it with local hacks.

## Repository Boundaries
Avoid unnecessary churn in:
- generated Xcode/project files unless required
- build artifacts / DerivedData
- unrelated docs in focused feature PRs
- app-wide settings/navigation files in unrelated bugfixes

## Validation Expectations
Before calling work “ready,” do the relevant validation for the scope:
- build
- targeted tests
- accessibility/permission review where applicable
- screenshots for visible UI changes when practical
- honest documentation of what was and was not validated

## Commit / PR Style
Commit message format:
- `feat: ...`
- `fix: ...`
- `refactor: ...`
- `docs: ...`
- `test: ...`
- `chore: ...`

PRs should include:
- what changed
- why it changed
- how it aligns with the product/design docs
- what validation was run
- any remaining caveats

## Current Priorities
Follow `docs/ROADMAP.md`, especially the App Store foundation work:
1. settings unification
2. export conversations
3. permission/App Review hardening
4. accessibility pass
5. UI smoke tests

These priorities outrank lower-value feature sprawl.
