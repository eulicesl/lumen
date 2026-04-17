# Contributing to Lumen

Lumen is **closed-source commercial software**, published publicly for portfolio, review, and reference purposes. See [`LICENSE`](LICENSE) for permitted use.

## If you are an external visitor

Thanks for reading the source. A few things to know:

- **Pull requests are not accepted** from outside contributors. The repository is public for transparency, but the product is maintained as a solo commercial project.
- **Bug reports are welcome**. The best path is TestFlight feedback (the shake-to-report flow inside the app). For security-sensitive reports, follow [`SECURITY.md`](SECURITY.md) instead.
- **Feature ideas are welcome** as GitHub issues if you want to leave a breadcrumb, but there is no commitment to triage or build them.
- **Re-use of source** is governed by [`LICENSE`](LICENSE) — the short version is _all rights reserved_. If you want to use any part of Lumen in your own project, open a GitHub issue or email [leulices@gmail.com](mailto:leulices@gmail.com) and we will talk.

If you are evaluating the repository for recruiting or collaboration purposes, the commit history on `main`, the closed PRs, and the docs in [`docs/`](docs/) are the artifact. Start with [`docs/ENGINEERING_STANDARD.md`](docs/ENGINEERING_STANDARD.md) and [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

---

## If you are an internal contributor

The rest of this document is the day-to-day workflow for anyone with write access to the repository.

### Branching

- **Never commit directly to `main`.** Branch protection enforces this; direct pushes are rejected.
- Start new work from a fresh branch off `main`:
  - `feature/<short-description>` — new user-visible capability
  - `fix/<short-description>` — bug fix
  - `chore/<short-description>` — refactor, dependency bump, tooling, docs
  - `release/<version>` — release-bump branches, e.g. `release/1.0.0-build-4`
- Keep branches short-lived. A branch that sits for more than a few days risks drifting from `main` and accumulating conflict surface.

### Commit messages

- Use [Conventional Commits](https://www.conventionalcommits.org) prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `perf:`, `build:`, `ci:`.
- Scope the commit with `(ios)`, `(release)`, `(docs)`, etc. when it clarifies intent.
- Write messages that read like a human engineer telling another engineer what changed and why. The body should answer "what problem did this solve and how?"
- Avoid shorthand or "wip" commits on branches that will end up on `main`. If you need to save work in progress, squash before opening the PR.

### Pull requests

- Open a PR into `main`. Title should match the conventional commit line that will end up on `main` after squash.
- The PR template in [`.github/pull_request_template.md`](.github/pull_request_template.md) enumerates the required sections. Fill in everything that applies; mark irrelevant sections as `None` rather than deleting them.
- **Do not merge with unresolved review conversations.** Branch protection enforces this.
- Address all automated review findings (CodeRabbit, Gemini Code Assist, ChatGPT Codex Connector). For false positives, reply explaining why you are dismissing the comment and then resolve the thread.
- Squash-merge only. Linear history is enforced on `main`.

### Local quality gate

Before opening a PR, verify locally:

1. **Build** — open in Xcode or run the simulator build command below. The build must compile clean.
2. **Tests** — run the unit test suite. It should report a passing count that matches or exceeds the baseline. Adding a test file without wiring it into the Xcode project's test target is treated as a bug, not a silent miss.
3. **Xcode navigator** — check for new issues or warnings you introduced. Deprecation warnings are treated as follow-up work, not blockers, but must be acknowledged.
4. **Targeted smoke test** — if you touched UI, run the app on a simulator and exercise the affected surface.

### Commands

```bash
# Legacy only: if you edit project.yml (scheduled removal — see docs/ENGINEERING_STANDARD.md)
xcodegen generate

# Build for a simulator (substitute a simulator UDID from `xcrun simctl list`)
xcodebuild build \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -destination "id=<simulator-udid>"

# Run the full test suite
xcodebuild test \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -destination "id=<simulator-udid>"

# Run tests, skipping UI tests
xcodebuild test \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -destination "id=<simulator-udid>" \
  -skip-testing:LumenUITests
```

### Release discipline

Releases ship from `main` or a `release/*` branch cut from `main`. Every shipped build maps to a single squash-merge commit on `main`. Build number is driven by `CURRENT_PROJECT_VERSION` in `Lumen.xcodeproj/project.pbxproj` and resolved into `Info.plist` via `$(CURRENT_PROJECT_VERSION)` substitution — there is one source of truth, never two.

Use the checklists before shipping:

- TestFlight build: [`TESTFLIGHT_RELEASE_PROCESS.md`](TESTFLIGHT_RELEASE_PROCESS.md)
- App Store submission: [`docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md`](docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md)

### Quality bar

Everything in this repo is maintained to the bar defined in [`docs/ENGINEERING_STANDARD.md`](docs/ENGINEERING_STANDARD.md). If a change would lower that bar, fix the underlying cause (test coverage, docs, CI, tooling) rather than accepting the regression.
