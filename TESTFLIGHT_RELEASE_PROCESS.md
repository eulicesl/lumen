# Lumen TestFlight Release Process

Treat TestFlight as a repeatable release pipeline, not an ad-hoc archive-and-upload exercise.

## Release rules
- Ship from `main` or `release/*` cut from `main` only.
- Every TestFlight build must map to a specific commit SHA.
- Do not release from a dirty working tree.
- Do not skip CI, local build, or smoke test just because a build "probably works".

## Versioning
- Set an intentional marketing version.
- Increment build number for every uploaded build.
- Keep app and extension versioning aligned where required.

## Preflight gate
Before cutting a TestFlight build:
- [ ] `main` is green in GitHub Actions
- [ ] PRs for this release scope are merged
- [ ] `xcodegen generate` run if project config changed
- [ ] Simulator build passes
- [ ] Unit tests pass
- [ ] Xcode navigator issues are clean
- [ ] Manual smoke test completed for touched flows
- [ ] Bundle identifier and signing settings are correct
- [ ] App Store Connect target app is confirmed

## Manual smoke test
Minimum regression checklist:
- [ ] App launches cleanly
- [ ] Onboarding flow works
- [ ] Chat send/response works
- [ ] Settings screen works
- [ ] Memory / Search / Compare features work if changed
- [ ] Widget loads if release touches widget functionality
- [ ] No critical layout breakage on target simulator/device sizes

## Build artifact discipline
Record for every release:
- Version:
- Build number:
- Git commit SHA:
- Xcode version:
- Target ASC app:
- Release notes summary:

## Submission hygiene
- Upload only from the approved release commit.
- Attach clear tester-facing release notes.
- If a build is bad, expire it quickly and cut a patch build.
- Before App Store submission, complete `docs/release/APP_STORE_SUBMISSION_CHECKLIST.md`.

## Post-upload QA
After upload processes in TestFlight:
- [ ] Install from TestFlight
- [ ] Re-run core regression pass on the distributed build
- [ ] Confirm no signing/provisioning/runtime surprises
- [ ] Confirm widget/permissions behavior on-device if relevant

## Security
- Never commit secrets, tokens, or local signing artifacts.
- If secrets are ever exposed in git history, rotate them immediately.
