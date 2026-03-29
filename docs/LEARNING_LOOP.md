# Lumen Learning Loop

## Purpose
Lumen should improve after every sprint, not just accumulate code.

This document defines the process for getting better after each run so the team, agents, and repository do not repeat the same mistakes.

## Principle
After every meaningful sprint, spike, or PR sequence, capture:
1. what worked
2. what failed
3. what created review friction
4. what slowed execution
5. what should change in the workflow, docs, or architecture rules

## Source of process memory
- `.ralphy/progress.txt` is the short-form running log.
- `docs/` files are updated when patterns repeat or when the repo contract should change.

## When to update the learning loop
Update after:
- each sprint close
- each major integration/rebase event
- each painful review cycle
- each repeated build/test/environment failure
- each time we discover that a rule should be added or tightened

## What to capture
### Good captures
- task parallelization conflict on shared files
- PR too large / hard to review
- validation step repeatedly forgotten
- a product rule that was implicit but needs to be documented
- a misleading micro-PRD that caused churn
- a branch naming / workflow issue that confused the sprint

### Bad captures
- vague diary entries
- emotional venting without a process correction
- raw implementation notes that belong in a PR or issue instead

## Required format for progress notes
Each note should be short and structured:
- **Context:** what task/sprint/PR this came from
- **Observation:** what happened
- **Impact:** why it mattered
- **Adjustment:** what should change next time

Example:
- Context: Sprint 1 parallel work
- Observation: Settings unification and permission hardening collided on shared settings files
- Impact: caused avoidable merge and review confusion
- Adjustment: mark settings architecture tasks as single-owner work in AGENTS.md and SPRINTS.md

## How the repo should improve over time
When the same type of issue appears twice, do not just note it again.
Instead, update one of:
- `CLAUDE.md`
- `AGENTS.md`
- `.ralphy/config.yaml`
- `docs/DESIGN.md`
- `docs/ROADMAP.md`
- the relevant micro-PRD

## Standing rule
The goal is not just to ship features.
The goal is to ship features while making the repo, process, and review quality better after every run.
