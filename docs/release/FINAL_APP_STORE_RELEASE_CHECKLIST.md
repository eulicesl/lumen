# Lumen Final App Store Release Checklist

This is the final pre-submit checklist for the first public App Store release of Lumen.

Use this document with:

- `docs/release/PRE_SUBMISSION_AUDIT.md` for the active ship/no-ship gate
- `docs/release/APP_STORE_SUBMISSION_CHECKLIST.md` for App Store Connect and signing workflow
- `docs/release/RELEASE_READINESS.md` for repository and packaging state
- `docs/release/DEVICE_QA_RUNBOOK.md` for physical-device pass/fail verification

## Audit Summary

Current repo and workflow quality are strong enough for submission work.

Current release blockers are concentrated in:

- final UI/accessibility verification on the exact release candidate
- reviewer-facing clarity for optional AI provider setup
- App Store-facing metadata and screenshot polish

## Must Fix Before Submission

- [ ] Replace developer/internal screenshot content with customer-facing example content.
  - Current generated screenshots are technically valid but still include internal-looking entries such as release/privacy checklist content.
  - Final screenshots should show polished everyday use cases: trip planning, document summarization, writing help, research, or brainstorming.
- [ ] Complete full physical-device QA on the exact release candidate build.
  - Required path: onboarding, new chat, starter prompt, send, retry, edit-and-resend, copy, save to memory, search jump, document import, settings, provider switch, privacy/support links.
- [ ] Complete a release-candidate Dynamic Type pass.
  - Verify default, large, and accessibility sizes on iPhone and iPad.
  - Focus on header chrome, starter prompts, message bubbles, composer, settings rows, search results, and memory screens.
- [ ] Complete a release-candidate accessibility pass with VoiceOver.
  - Verify all primary actions are labeled, actionable, and understandable without sight.
  - Focus on model picker chip, tools menu, composer actions, retry/edit banners, message actions, provider sections, and imported document chips.
- [ ] Verify light mode and dark mode polish on the release build.
  - Current screenshot harness output is dark-mode only; light-mode visual parity still needs explicit signoff.
- [ ] Finalize reviewer notes for Apple.
  - Explain that Apple Intelligence is the primary reviewer path on supported devices and does not require account creation, login, or third-party credentials.
  - Explain that Ollama Local and Ollama Cloud are optional advanced providers and not required to review the app.
  - Provide exact reviewer steps for a successful Apple Intelligence-only review path.
  - Add fallback guidance for devices where Apple Intelligence is unavailable.
- [ ] Validate the release binary on at least one non-ideal environment path.
  - Example: device without Apple Intelligence availability, or with Ollama disabled, to confirm graceful fallback messaging.

## Strongly Recommended Before Submission

- [ ] Improve App Store screenshot art direction.
  - Use cleaner, more aspirational seeded conversations.
  - Avoid internal product-management or release-ops language in screenshots.
- [ ] Re-check iPad composition for presentation quality.
  - The current iPad capture is functional, but final store imagery should feel intentionally composed, not just mechanically captured.
- [ ] Confirm empty states remain useful and elegant when no local/cloud provider is enabled.
- [ ] Confirm Liquid Glass usage feels restrained and native, not decorative.
- [ ] Confirm all support/privacy URLs open correctly on device.

## Apple Review Risk Checklist

- [ ] No crashes, hangs, dead buttons, or broken navigation on the primary path.
- [ ] No placeholder copy, incomplete content, or obviously in-progress UI in the shipping build.
- [ ] Metadata, screenshots, privacy answers, and reviewer notes all match the actual binary.
- [ ] The app remains useful without requiring a private backend or reviewer-specific credentials.
- [ ] If Ollama connectivity is unavailable during review, the app still demonstrates real value via Apple Intelligence on supported hardware.
- [ ] Any network-dependent behavior has a clear error state and recovery path.

## Apple HIG / Platform Quality Checklist

- [ ] Navigation is simple and predictable on iPhone and iPad.
- [ ] Touch targets remain comfortable at all supported Dynamic Type sizes.
- [ ] Motion respects `Reduce Motion` across onboarding, loading, and chat affordances.
- [ ] Visual hierarchy is clear in both compact and regular width environments.
- [ ] Settings content reads like system-quality configuration, not developer/debug UI.
- [ ] Forms and rows use concise labels, short helper copy, and stable grouping.
- [ ] Primary actions are visually obvious without overwhelming the interface.
- [ ] Sidebars, sheets, and modal presentations feel appropriate for each idiom.

## Technical Quality Checklist

- [ ] `main` is green in GitHub Actions.
- [ ] Local tests pass on the release commit.
- [ ] The release commit is tagged before submission.
- [ ] App version and build number are intentional for the upload.
- [ ] Archive and IPA export are repeated once from the final release commit.
- [ ] `PrivacyInfo.xcprivacy` matches the shipped implementation.
- [ ] Optional provider credentials are stored securely and migration behavior is verified.

## Submission Package Checklist

- [ ] Final screenshots exported from the approved release candidate.
- [ ] Final App Store description, subtitle, keywords, promotional text, and release notes entered.
- [ ] Privacy Policy URL is live and accurate.
- [ ] Support URL is live and accurate.
- [ ] App Review notes are specific, concise, and truthful.
- [ ] App Store privacy questionnaire answers match the binary.
- [ ] Uploaded build finishes processing in App Store Connect.
- [ ] Post-upload TestFlight install succeeds on a physical device.

## Release Decision

Submit only when every item in `Must Fix Before Submission` is complete and there is no known issue that would cause App Review to perceive the app as incomplete, misleading, or dependent on unavailable setup.
