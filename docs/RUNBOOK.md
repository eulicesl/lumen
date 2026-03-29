# Lumen Runbook

## Purpose
This file explains how to operate Lumen sprints in practice using the Ralphy-style workflow already configured in the repo.

## Step 1 — Choose the current sprint
Start from:
- `docs/SPRINTS.md`
- the current sprint execution doc (for example `docs/SPRINT_1_EXECUTION.md`)

## Step 2 — Pick task branches
Each micro-PRD gets its own branch.
Examples:
- `sprint/001-settings-unification`
- `sprint/002-export-conversations`
- `sprint/003-permission-hardening`

## Step 3 — Decide what can run in parallel
Use the sprint execution doc plus these rules:
- isolated tasks can run in parallel
- shared shell/settings/provider tasks should be solo or tightly coordinated

## Step 4 — Execute with repo rules
Follow:
- `CLAUDE.md`
- `AGENTS.md`
- `.ralphy/config.yaml`

## Step 5 — Validate honestly
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
