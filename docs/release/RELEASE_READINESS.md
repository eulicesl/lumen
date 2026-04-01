# Lumen Release Readiness

This document tracks the gap between a healthy repository and an actual App Store submission.

## Completed in repo

- Original-work/authorship position is documented in `README.md` and `docs/PORTFOLIO_AUTHORSHIP.md`.
- TestFlight and App Store submission checklists exist and are part of the repository workflow.
- App version metadata is now defined intentionally in repository configuration instead of being left as an undocumented default.
- Public privacy and support pages are now live at <https://eulicesl.github.io/lumen/privacy/> and <https://eulicesl.github.io/lumen/support/>.
- Draft App Store metadata, privacy answers, reviewer notes, and screenshot planning now exist in-repo.
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

## Submission rule

Do not claim the app is ready for App Store submission until both conditions are true:

1. the repository release checklist is complete, and
2. the external App Store Connect inputs above are prepared and verified.
