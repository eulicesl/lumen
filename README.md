# Lumen

Lumen is a native SwiftUI app treated as a real product from day one: private repo, PR-based workflow, CI on every PR, and release discipline.

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
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Run tests
```bash
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 16' -skip-testing:LumenUITests test
```

## Release discipline
- Ship from `main` or a `release/*` branch cut from `main`.
- Every shipped build must map to a commit SHA.
- Use the checklist in `TESTFLIGHT_RELEASE_PROCESS.md` before any TestFlight release.
