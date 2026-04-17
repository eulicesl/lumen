# Architecture Decision Records

This directory records architectural decisions that shape Lumen. Each record is a short, dated, immutable document capturing one decision and its tradeoffs.

## Why we keep ADRs

- The rationale behind a decision is easy to lose once the PR that introduced it scrolls off the first page of `git log`.
- [`docs/ENGINEERING_STANDARD.md`](../ENGINEERING_STANDARD.md) requires decisions to be "auditable" and rollback paths to be "written down." ADRs are the artifact that satisfies that requirement.
- Portfolio reviewers and future contributors (including future-me) can reconstruct the "why" without interviewing anyone.

## What counts as an ADR

Write one when the change introduces or alters:

- a platform or deployment floor (e.g. "macOS 15.0 minimum")
- a cross-cutting architectural pattern (e.g. stores over view-models, provider abstraction shape)
- a dependency choice with lock-in cost (e.g. SwiftData over GRDB, FoundationModels over CoreML)
- a security, privacy, or data-handling posture
- a process change that affects more than one PR

Do **not** write one for:

- bug fixes
- refactors that preserve behavior and introduce no new pattern
- purely cosmetic changes
- routine dependency bumps

If in doubt, err on the side of writing one. A ten-minute ADR now is cheaper than a forty-five-minute archaeology session later.

## File naming

- `NNNN-kebab-case-title.md`, where `NNNN` is a four-digit zero-padded integer.
- Numbers are never reused and never skipped. Do not renumber on delete; mark the record as Deprecated instead.
- [`template.md`](template.md) holds the current template and is copied as the starting point for new records.

## Status lifecycle

Every ADR carries a single Status line near the top:

- **Proposed** — the decision is written down but not yet in force. Used when the ADR lands before the implementing PR.
- **Accepted YYYY-MM-DD** — the decision is in force.
- **Superseded by NNNN on YYYY-MM-DD** — a later ADR overrode this one. The old record stays; its body is not edited.
- **Deprecated on YYYY-MM-DD** — the decision is no longer relevant (e.g. the feature was removed). The old record stays.

**Immutability rule:** once an ADR is Accepted, its body is not edited. If circumstances change, write a new ADR that supersedes it, and only update the Status line of the old record to point forward. Typo fixes and broken-link repairs are the only exceptions.

## How to add one

1. Pick the next integer in the index below.
2. `cp docs/adr/template.md docs/adr/NNNN-your-title.md`
3. Fill in every section. An ADR with no rejected alternative is a post-hoc justification, not a decision record.
4. Open it as its own PR (or include it in the PR that implements the decision). Do not bundle unrelated ADRs into the same PR.
5. Update the index in this README in the same commit.

## Index

| ID | Title | Status |
|----|-------|--------|
| [0000](0000-record-architecture-decisions.md) | Record architecture decisions | Accepted 2026-04-16 |
| [0001](0001-add-native-macos-target.md) | Add a native macOS app target | Accepted 2026-04-16 |

## Further reading

- Michael Nygard, ["Documenting Architecture Decisions"](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) (2011) — the original practice this repo follows.
