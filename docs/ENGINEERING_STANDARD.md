# Lumen Engineering Standard

This repository is maintained as a **portfolio-grade product artifact**.
The quality bar is intentionally set to senior engineer/company standards.

## Non-negotiables

- Reproducible: work is repeatable from clean checkout.
- Reviewable: PR scope is tight, rationale is explicit, risk is documented.
- Test-gated: changes are validated with deterministic checks + human verification.
- Secure: no secret leakage, least-privilege mindset, privacy-aware implementation.
- Auditable: decisions, validation evidence, and rollback paths are written down.

## Branch and PR discipline

- Never ship feature work directly on `main`.
- One concern per PR; avoid stacked PR confusion unless explicitly planned.
- Superseded/overlapping PRs are closed with explicit references.
- Merge only when CI is green, review requirements are met, and high-risk comments are resolved.

## Required PR quality

Every PR must include:
- problem statement + why it matters
- scope boundary (what changed / what did not)
- concrete validation steps and evidence (screenshots/logs/tests)
- risk + mitigation + rollback plan
- unresolved items clearly marked as follow-up (not hidden)

## iOS / Apple-grade expectations

- API availability is explicit (`#available`) where needed.
- Native platform behavior is preferred over heavy custom abstractions for core shell UX.
- Device validation is done for UI-affecting changes before merge.
- Visual verification artifacts are captured for UI-affecting PRs and called out in the PR evidence.
- Launch/orientation/privacy config is treated as product quality, not "later" work.

## Documentation quality

- Docs are concise, current, and actionable.
- Commands in docs are runnable as written.
- Process docs are treated as product code (reviewed, versioned, maintained).

## Release quality

- Build provenance is clear (commit SHA ↔ shipped build).
- Release checklist is followed before TestFlight/App Store submission.
- Regressions trigger a patch workflow, not ad-hoc fixes on main.

## Definition of done

A change is done only when:
1. code quality is acceptable,
2. validation evidence exists,
3. documentation is updated if behavior/process changed,
4. merge risk is low and explicitly understood.
