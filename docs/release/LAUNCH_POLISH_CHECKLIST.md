# Lumen Launch Polish Checklist

This checklist maps the current pre-launch UI issues observed in the app review video to concrete source areas and shipping actions.

## P0 — Must Fix Before Launch

- [x] Prevent internal agent/tool markup from leaking into visible chat content.
  - Risk: unfinished / untrustworthy product feel.
  - Source areas:
    - `Lumen/Models/AgentTool.swift`
    - `Lumen/Services/AgentService.swift`
    - `Lumen/Views/Shared/Chat/MessageBubbleView.swift`
    - `Lumen/Extensions/String+Markdown.swift`
- [x] Replace weak first-run starter prompts with customer-facing examples that succeed without prompt repair.
  - Risk: poor first impression, value not demonstrated fast enough.
  - Source areas:
    - `Lumen/Models/SavedPrompt.swift`
    - `Lumen/Views/Shared/Chat/ChatView.swift`
- [ ] Verify reviewer path stays clear on first launch with Apple Intelligence only.
  - Risk: App Review confusion about optional providers.
  - Source areas:
    - `docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md`
    - reviewer notes / App Store Connect metadata

## P1 — Strongly Recommended Before Launch

- [x] Reduce iPhone header chrome so navigation reads as calm and obvious.
  - Risk: crowded first impression, truncated title, weak hierarchy.
  - Source area:
    - `Lumen/Views/iOS/MainTabView.swift`
- [x] Improve long assistant-response readability.
  - Risk: dense, model-output feeling rather than polished iPhone reading.
  - Source area:
    - `Lumen/Views/Shared/Chat/MessageBubbleView.swift`
- [x] Replace screenshot/demo content with polished customer-facing conversations.
  - Risk: App Review and App Store asset quality.
  - Source areas:
    - `docs/release/PRE_SUBMISSION_AUDIT.md`
    - `docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md`
    - screenshot capture harness output
  - Implemented in:
    - `Lumen/App/ReleaseCaptureHarness.swift`
    - `Lumen/App/AppLaunchConfiguration.swift`

## P2 — Needs Direct Verification / Follow-up

- [~] Mitigate the likely right-edge side affordance and confirm the visual result on device.
  - Current status: the strongest source candidate was `ChatView`'s floating trailing scroll-to-latest button, which has been softened into a bottom-centered capsule. The exact frame-to-code match still needs visual verification.
- [ ] Run a release-candidate Dynamic Type pass focused on the primary iPhone shell.
- [ ] Run a release-candidate VoiceOver / accessibility semantics pass.
- [ ] Run light-mode and dark-mode polish pass on device.
- [ ] Capture final App Store screenshots from the polished build.
- [ ] Complete full physical-device QA on the exact release candidate.

## PR Plan

### PR 1 — launch polish pass 1
- Tool-markup sanitization
- stronger starter prompts
- lighter iPhone header chrome
- message readability improvements

### PR 2 — release candidate polish / verification
- screenshot content refresh
- Dynamic Type / accessibility fixes from device pass
- any residual shell polish found in QA

### PR 3 — submission readiness
- reviewer notes / metadata alignment
- final checklist closure
