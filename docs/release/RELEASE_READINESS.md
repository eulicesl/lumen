# Lumen Release Readiness

This document tracks the gap between a healthy repository and an actual App Store submission.

## Completed in repo

- Original-work/authorship position is documented in `README.md` and `docs/PORTFOLIO_AUTHORSHIP.md`.
- TestFlight and App Store submission checklists exist and are part of the repository workflow.
- App version metadata is now defined intentionally in repository configuration instead of being left as an undocumented default.
- Public privacy and support pages are now live at <https://eulicesl.github.io/lumen/privacy/> and <https://eulicesl.github.io/lumen/support/>.
- Draft App Store metadata, privacy answers, reviewer notes, and screenshot planning now exist in-repo.
- A dedicated pre-submission go/no-go audit now exists at `docs/release/PRE_SUBMISSION_AUDIT.md`.
- The repository now includes a GitHub Pages deployment workflow at `.github/workflows/pages.yml` and a public-site source tree at `site/` for release-facing privacy and support URLs.
- Stale Calendar and Reminders permission strings were removed from project configuration because the current codebase does not use EventKit.
- Release candidates are expected to carry fresh local validation evidence before submission.

## Remaining external blockers

These items cannot be completed purely through repository edits:

- Final App Store metadata:
  - app description
  - subtitle
  - keywords
  - promotional text
  - reviewer notes
- Final screenshot set captured from the release candidate
- App Store Connect app record review and privacy questionnaire entry
- Signed archive upload using the final Apple account and distribution setup

## Verified local packaging state

The current repository is archive-ready and can produce an App Store IPA locally:

- `xcodebuild archive` succeeds for `Lumen`
- `./scripts/export_app_store_archive.sh` succeeds and exports an IPA from `build/Lumen.xcarchive`
- `exportOptions-appstore.plist` is aligned to the active team `8394UJXX4F`

One local environment caveat is now documented in the export script: if Homebrew `rsync` appears ahead of `/usr/bin` in `PATH`, `xcodebuild -exportArchive` can fail with a generic `Copy failed` packaging error. The script forces the system toolchain order so release packaging is reproducible.

## Remaining external submission blockers

App Store submission still depends on Apple-account state that cannot be fixed purely in the repository:

- App Store Connect access for the final submitting account
- uploaded build processing in App Store Connect
- final metadata/privacy form entry in App Store Connect

## Ongoing release governance

- Memory relevance roadmap is phase-gated (`docs/product/sprints/2026-sprint-05-memory-relevance.md`).
- Before any Sprint 05 Phase 2/3 implementation, record a go/no-go decision in the Sprint 05 Decision Log.

## Submission rule

Do not claim the app is ready for App Store submission until both conditions are true:

1. the repository release checklist is complete, and
2. the external App Store Connect inputs above are prepared and verified.
