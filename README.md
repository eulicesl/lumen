# Lumen

Lumen is a native SwiftUI app treated as a real product from day one: private repo, PR-based workflow, CI on every PR, and release discipline.

## Authorship
Lumen is original work by Eulices and was built from scratch in this repository as a native Apple-platform product.
It is not a fork, clone, or white-label template.
AI tooling was used as an engineering aid for implementation speed, review loops, and documentation refinement, but product direction, technical judgment, code ownership, and final quality decisions remain Eulices's responsibility.

## Engineering workflow
- Do **not** work directly on `main`.
- Start new work with:
  - `./scripts/new-feature.sh <name>`
- Branch naming:
  - `feature/<name>`
  - `fix/<name>`
  - `chore/<name>`
  - `release/<version>`
- Open a PR back into `main`.
- Merge only after CI is green and review is complete.
- Maintain the portfolio-grade engineering bar in `docs/ENGINEERING_STANDARD.md`.

## Local setup
### Prerequisites
- Xcode 26+
- xcodegen (`brew install xcodegen`)

### Open the project
```bash
cd ~/projects/lumen
xcodegen generate
open Lumen.xcodeproj
```

## Validation
### Build for simulator
```bash
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=<available-simulator>' build
```

### Run tests
```bash
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=<available-simulator>' -skip-testing:LumenUITests test
```

## Release discipline
- Ship from `main` or a `release/*` branch cut from `main`.
- Every shipped build must map to a commit SHA.
- Use the checklist in `TESTFLIGHT_RELEASE_PROCESS.md` before any TestFlight release.
- Use `docs/release/APP_STORE_SUBMISSION_CHECKLIST.md` before App Store submission.

## Product and design docs
- Product PRD (execution): `docs/product/PRD.md`
- Feature parity checklist: `docs/product/feature-parity-checklist.md`
- Sprint micro PRDs: `docs/product/sprints/`
- Design doc target path / current pointer: `docs/design/design.md`
- Portfolio authorship note: `docs/PORTFOLIO_AUTHORSHIP.md`
- App Store submission checklist: `docs/release/APP_STORE_SUBMISSION_CHECKLIST.md`
- Release readiness status: `docs/release/RELEASE_READINESS.md`
- App Store metadata draft: `docs/release/APP_STORE_METADATA_DRAFT.md`
- App Review notes draft: `docs/release/APP_REVIEW_NOTES.md`
- App privacy questionnaire draft: `docs/release/APP_PRIVACY_QUESTIONNAIRE_DRAFT.md`
- Screenshot capture plan: `docs/release/SCREENSHOT_CAPTURE_PLAN.md`
- Privacy policy draft: `docs/legal/PRIVACY_POLICY.md`
- Support page draft: `docs/support/SUPPORT.md`
