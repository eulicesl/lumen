# 0000: Record architecture decisions

- **Status:** Accepted 2026-04-16
- **Date:** 2026-04-16
- **Deciders:** Eulices Lopez
- **Related:** [`docs/ENGINEERING_STANDARD.md`](../ENGINEERING_STANDARD.md), [`docs/WORKFLOW.md`](../WORKFLOW.md)

## Context

Lumen is maintained to a portfolio-grade engineering bar that explicitly requires decisions to be "auditable" and rollback paths to be "written down." Today, rationale for architectural decisions lives in three places:

1. Commit messages on `main`.
2. PR descriptions once those PRs are closed.
3. In-line comments and docstrings.

Each is useful at the moment of merge but hard to discover later. A new contributor — or the author returning after six months — asking "why macOS 15 and not 14?" has to search `git log`, scan closed PRs, and reconstruct context from memory. That is work the original author could have prevented with a few minutes of writing.

Several adjacent problems compound this:

- Some decisions span multiple PRs and have no single commit to point at.
- Some decisions are made in planning conversations that never land in the repo.
- "Why did we reject X?" is asked more often than "what did we choose?", and commit messages rarely answer the first question.

## Decision

Adopt Michael Nygard–style Architecture Decision Records, stored in `docs/adr/` as numbered, dated, immutable Markdown files following the template in [`template.md`](template.md). The format, naming, status lifecycle, and authoring rules are described in [`README.md`](README.md).

## Alternatives considered

- **Keep rationale in PR descriptions only.** **Rejected because:** PR descriptions are searchable but not indexed in the repo, and their tone is transactional ("this PR does X") rather than decision-focused ("we chose X over Y because Z"). They also cannot capture decisions that span multiple PRs.
- **Long-form design docs per decision (Google-style one-pagers).** **Rejected because:** over-engineered for a solo-maintained repo; the format invites scope creep and buries the decision inside background. Nygard ADRs are deliberately short and force the writer to commit to alternatives and consequences.
- **External wiki (Confluence, Notion, a GitHub wiki).** **Rejected because:** moves the source of truth outside the repo, breaks the "code and rationale ship together" invariant, and requires a separate access policy for public portfolio reviewers.

## Consequences

- **Positive:** decisions become greppable, reviewable, and linkable; portfolio reviewers have a single directory that shows architectural reasoning; future contributors have a reliable artifact for onboarding and for de-risking changes.
- **Negative:** every non-trivial architectural change now carries a ten-to-thirty-minute documentation cost. Some decisions will be written down that turn out to be uninteresting in hindsight.
- **Neutral:** the practice requires discipline to actually use. An ADR directory with three stale entries is worse than no ADR directory — it suggests the practice exists but is not followed.

## Revisit trigger

If fewer than three ADRs are added in any twelve-month period during which non-trivial architectural decisions were made, the practice is not working. Reassess whether the overhead is justified or whether the bar for "non-trivial" has drifted.

## References

- Michael Nygard, ["Documenting Architecture Decisions"](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) (2011).
- [`docs/ENGINEERING_STANDARD.md`](../ENGINEERING_STANDARD.md) — "Auditable: decisions, validation evidence, and rollback paths are written down."
- [`docs/WORKFLOW.md`](../WORKFLOW.md) — PR-level rationale requirements that ADRs complement.
