# Lumen Runbook

## Purpose
This file explains how to operate Lumen sprints in practice using the Ralphy-style workflow already configured in the repo.

## Step 1 — Choose the current sprint
Start from:
- `docs/SPRINTS.md`
- the current sprint execution doc (for example `docs/SPRINT_1_EXECUTION.md`)

## Step 2 — Pick the execution source
Use the richer docs for product/design understanding, and the machine-readable task file for actual sprint execution.

For Sprint 1, the execution source is:
- `tasks/sprint-1.yaml`

This file defines:
- task titles
- completion state
- `parallel_group` sequencing

## Step 3 — Pick task branches
Each task gets its own branch.
Examples:
- `ralphy/settings-unification`
- `ralphy/export-conversations`
- `ralphy/permission-hardening`

## Step 4 — Decide what can run in parallel
Use the task file's `parallel_group` first, then apply repo architecture judgment:
- same `parallel_group` may run together
- shared shell/settings/provider tasks should still be treated cautiously even if the plan says they are in scope for the same sprint

## Step 5 — Execute with repo rules
Follow:
- `CLAUDE.md`
- `AGENTS.md`
- `.ralphy/config.yaml`

## Sandbox vs Worktree
Default to real branch/worktree-style execution when branch integrity and git visibility matter.
Use sandbox-style execution only when repository size or dependency duplication makes it materially faster and safer.

Prefer branch/worktree mode for:
- shared architecture work
- shell/settings/provider changes
- any task where real git context matters

Sandbox mode is more acceptable for:
- isolated docs tasks
- self-contained feature work
- large dependency-heavy repos where copying full worktrees is wasteful

## Protected files
Agents should not modify during normal implementation work:
- `tasks/*.yaml`
- `.ralphy/progress.txt`
- `.ralphy-worktrees/**`
- `.ralphy-sandboxes/**`

These are control-plane artifacts, not feature implementation targets.

## Step 6 — Validate honestly
Run the most relevant validation available for the task:
- build
- targeted tests
- UI checks
- screenshots for visible UI changes where practical

If something cannot be validated in the current environment, document that honestly in the PR.

## Step 6 — Open PRs cleanly
- one concern per PR
- use draft PRs when incomplete
- do not mix architecture, bugfix, and unrelated cleanup in one branch

## Step 7 — Learn after the run
After a sprint or meaningful task run:
- append short notes to `.ralphy/progress.txt`
- if a pattern repeats, update docs/rules/config
- follow `docs/LEARNING_LOOP.md`

## Escalation Rules
Stop and escalate/document instead of improvising when:
- multiple tasks begin touching the same shared architecture
- product direction conflicts with existing docs
- a task reveals a larger architecture issue than its scope allows
- validation blockers require repo-level process changes

## Standard
The goal is not just shipping features.
The goal is shipping features in a way that makes Lumen look and feel like a serious product built by disciplined senior engineers.
