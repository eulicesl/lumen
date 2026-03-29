# Lumen Workflow

This repository follows a **Ralphy-style task execution model**.

## Core Model
- tasks come from `docs/micro-prds/` and related planning docs
- one task = one branch
- branch-per-task is the default
- isolated tasks may run in parallel
- shared architecture work should be sequenced carefully
- use draft PRs when work is not fully validated

## Source of Truth
Before starting work, consult:
- `docs/PRD.md`
- `docs/DESIGN.md`
- `docs/ROADMAP.md`
- `docs/SPRINTS.md`
- `docs/SPRINT_1_EXECUTION.md` (or current sprint execution doc)
- `docs/micro-prds/`
- `CLAUDE.md`
- `AGENTS.md`
- `.ralphy/config.yaml`

## Branch Workflow
### Default
- create one branch per task
- branch naming should be explicit and task-oriented
- use draft PRs when validation is incomplete

Recommended examples:
- `sprint/001-settings-unification`
- `sprint/002-export-conversations`
- `sprint/003-permission-hardening`

Ralphy-style branch naming such as `ralphy/<task-slug>` is also valid if the sprint lead chooses to use it consistently.

## Parallel Work
### Allowed
Parallel work is allowed when tasks are truly isolated.

Examples of safe parallelism:
- export work vs permission hardening
- accessibility work vs docs/support work
- tags/filters vs import/restore when data models are stable

### Not allowed casually
Do not parallelize tasks that touch shared architecture without explicit coordination.
This includes:
- app shell/navigation
- settings architecture
- provider/tooling architecture
- shared chat/store core

If tasks collide on shared files, sequence them or assign a single owner.

## Pull Requests
A PR should:
- represent one logical concern
- be reviewer-friendly
- include honest validation notes
- avoid unrelated cleanup
- include screenshots for visible UI changes when practical

Use draft PRs when:
- validation is incomplete
- device testing is pending
- the task is intentionally in review before final polish

## Merge Standard
Prefer squash merge unless there is a good reason not to.
Keep `main` clean, readable, and releasable.

## Learning Loop
After meaningful runs or sprint completion:
- append process learnings to `.ralphy/progress.txt`
- if a pattern repeats, update repo rules/docs instead of only logging it again
- follow `docs/LEARNING_LOOP.md`

## Professional Standard
This repo should read like it is maintained by disciplined senior engineers:
- small scoped changes
- clear intent
- native Apple API preference
- App Store-quality judgment
- no noisy amateur branch/PR behavior
