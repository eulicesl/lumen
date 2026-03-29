# Contributing to Lumen

## Workflow
- Never commit directly to `main` for feature work.
- Create a short-lived branch from `main`:
  - `feature/<name>`
  - `fix/<name>`
  - `chore/<name>`
- Open a pull request back into `main`.
- Merge only after CI is green and required review is satisfied.

## Local quality gate
Before opening a PR:
1. Build in Xcode for simulator.
2. Run unit tests.
3. Check Xcode navigator issues.
4. Do a targeted simulator smoke test for the touched flows.

## Preferred commands
```bash
# Regenerate project if project.yml changes
xcodegen generate

# Build for simulator
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests
xcodebuild -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 16' -skip-testing:LumenUITests test
```

## PR expectations
- Keep PRs small enough to review.
- Include screenshots for UI changes.
- Note any trade-offs or follow-up work.
- Do not merge with unresolved high-risk review comments.
