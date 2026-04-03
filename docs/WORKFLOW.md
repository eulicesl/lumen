# Lumen Workflow

## Branching
Always merge the previous PR before creating the next feature branch.

Why:
- stacked PRs make review noisy
- squash merges make rebases painful
- branch drift causes avoidable conflict recovery work

Correct flow:
1. Merge previous PR to `main`
2. Run `./scripts/new-feature.sh <next-feature>`
3. Implement changes
4. Push branch and open PR
5. Wait for CI + review
6. Merge

## Pull requests
A PR is mergeable only when:
- CI is green
- required review is present
- conversation threads are resolved
- no known high-risk blocker remains
- UI-affecting changes have visual verification evidence from the branch being merged

## Review standard
Prefer senior-engineer judgment:
- small scope
- explicit validation
- screenshots for UI changes
- written note of exactly what was visually verified
- follow-up notes when deferring non-blockers

## Merge standard
Prefer squash merge unless there is a specific reason not to.
Keep `main` clean, readable, and releasable.

## Quality bar
Treat this repo as a portfolio-grade artifact:
- `docs/ENGINEERING_STANDARD.md` is the canonical engineering bar.
- Workflow/process debt should be fixed proactively (not deferred indefinitely).
