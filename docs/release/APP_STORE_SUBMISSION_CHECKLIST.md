# Lumen App Store Submission Checklist

Treat App Store submission as a release artifact, not a last-minute form fill.

Use `docs/release/PRE_SUBMISSION_AUDIT.md` as the active go/no-go summary for whether the current build should ship.

## Provenance

- [ ] Release branch or `main` commit is identified
- [ ] Build maps to a specific git commit SHA
- [ ] Authorship and portfolio positioning remain accurate in `README.md` and `docs/PORTFOLIO_AUTHORSHIP.md`

## Product quality gate

- [ ] `main` is green in GitHub Actions
- [ ] Local unit tests pass
- [ ] Device smoke test completed on the release candidate
- [ ] Accessibility, Dynamic Type, and Reduce Motion regressions checked on the release build
- [ ] No known P0 or App Review-blocking defect remains open

## Versioning and build metadata

- [ ] Marketing version is intentional
- [ ] Build number is incremented for the upload
- [ ] App and widget version/build values are aligned and verified for the release candidate

## Privacy and permissions

- [ ] `PrivacyInfo.xcprivacy` matches the shipped binary
- [ ] Every declared permission has a real in-app use case
- [ ] Permission copy is user-readable and specific
- [ ] App Store privacy answers are prepared from the current implementation
- [ ] Privacy Policy URL is available for App Store Connect entry (<https://eulicesl.github.io/lumen/privacy/>)

## App Store Connect metadata

- [ ] App name, subtitle, and description are finalized
- [ ] Keywords are intentional and not spammy
- [ ] Support URL is available (<https://eulicesl.github.io/lumen/support/>)
- [ ] Marketing URL is set if desired
- [ ] Age rating and content declarations are reviewed
- [ ] Export compliance answers are prepared

## Assets

- [ ] App icon is final and matches the shipped build
- [ ] Required iPhone screenshots are captured from the current release candidate
- [ ] iPad screenshots are captured if iPad distribution is enabled
- [ ] Promotional text and release notes are written

## Signing and distribution

- [ ] Correct team, bundle identifier, and signing configuration are selected
- [ ] App Store export settings match the active Apple team (`8394UJXX4F`)
- [ ] Xcode account credentials are valid and refreshed locally
- [ ] An App Store distribution profile exists for `com.eulices.lumen`
- [ ] Archive completes cleanly in Xcode
- [ ] IPA export completes with `./scripts/export_app_store_archive.sh`
- [ ] Validation passes before upload
- [ ] Uploaded build appears in App Store Connect and processes successfully

## Final submission gate

- [ ] Submission uses the approved release commit only
- [ ] Reviewer notes are included if the app depends on local-network or model-host setup
- [ ] Post-upload TestFlight install succeeds on a physical device
- [ ] Final submitter has verified the exact build number and version being sent for review
