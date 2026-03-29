# AGENTS.md — Lumen Multi-Agent Workflow

This repository is executed using a **micro-PRD, branch-per-task, reviewer-friendly** workflow inspired by Ralphy.

## Working Model
### Source documents
Execution should follow this hierarchy:
1. `docs/PRD.md` — product truth
2. `docs/DESIGN.md` — architecture and UX truth
3. `docs/ROADMAP.md` — sequencing truth
4. `docs/micro-prds/` — sprint/task truth
5. `CLAUDE.md` — repo execution rules

If a proposed task conflicts with these docs, update the docs intentionally or raise the conflict instead of freelancing a solution.

## Sprint Structure
### Sprint 0 — Foundation
- product/docs/config setup
- execution rules
- branch/PR conventions

### Sprint 1 — App Store foundations
- settings unification
- export conversations
- permission hardening

### Sprint 2 — Quality/trust
- accessibility pass
- UI smoke tests
- support/privacy/product surface

### Sprint 3+
- organization
- portability completion
- architecture refinement
- premium polish

## Task Execution Rules
- One micro-PRD per task branch.
- One concern per PR.
- Prefer multiple small clean PRs over one mixed-purpose branch.
- If a change is broad, split bugfixes, modernization, and architecture work into separate PRs.

## Branch Naming
Default to Ralphy-style task branches:
- `ralphy/settings-unification`
- `ralphy/export-conversations`
- `ralphy/permission-hardening`

If a sprint lead chooses a different naming convention, it must be intentional, documented, and applied consistently across the sprint.

## Parallelization Rules
### Safe to parallelize
- isolated docs tasks
- export work vs permission UX work
- accessibility vs support/docs work
- tags/filtering vs import/restore when data models are stable

### Do not parallelize casually
- app shell/navigation refactors
- settings architecture changes
- provider/tooling architecture changes
- chat core / shared store changes

If multiple tasks touch the same shared files, assign a single owner or serialize the work.

## Review Bar
Every PR should feel like it came from a strong senior Apple engineer:
- clear scope
- coherent naming
- minimal churn
- no AI-generated slop
- native API preference
- honest validation notes

## Product Fit Rules
When borrowing from `enchanted-private`:
- port maturity and proven patterns
- do not port complexity for its own sake
- preserve Lumen’s simpler privacy-first/local-first identity

## Validation Rules
For each task, run the most relevant validation available:
- build
- targeted tests
- UI review for visible changes
- permission/accessibility review where applicable
- screenshots for visible UI changes when possible

If something cannot be validated in the current environment, document that honestly.

## Protected Files
Do not modify the execution/control-plane files during feature implementation unless the task explicitly targets workflow/process changes:
- `tasks/*.yaml`
- `.ralphy/progress.txt`
- `.ralphy-worktrees/**`
- `.ralphy-sandboxes/**`

## Learning Loop
- After meaningful runs, append concise process learnings to `.ralphy/progress.txt`.
- If a pattern repeats, update the repo rules/docs rather than only logging it again.
- See `docs/LEARNING_LOOP.md` for the expected format and escalation rule.

## Draft PR Policy
- Use draft PRs when work is still under validation.
- Keep upstream-facing work clean and intentional.
- Do not open noisy or premature PRs that waste reviewer attention.

## Deliverable Standard
A task is only complete when:
- implementation is coherent
- docs/PR narrative are clear
- validation has been run or honestly bounded
- the result fits the PRD/design direction
