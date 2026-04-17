# 0001: Add a native macOS app target

- **Status:** Accepted 2026-04-16
- **Date:** 2026-04-16
- **Deciders:** Eulices Lopez
- **Related:** [`0000-record-architecture-decisions.md`](0000-record-architecture-decisions.md), [`docs/product/feature-parity-checklist.md`](../product/feature-parity-checklist.md)

## Context

Lumen ships today as an iOS 26 app. Product intent spans Apple platforms, and the Mac is a natural surface for an assistant workflow — a user reading code, docs, or research on a Mac benefits materially from a persistent window they can talk to. [`docs/ENGINEERING_STANDARD.md`](../ENGINEERING_STANDARD.md) already names platform-native behavior as a quality bar, and [`README.md`](../../README.md) and [`docs/PORTFOLIO_AUTHORSHIP.md`](../PORTFOLIO_AUTHORSHIP.md) both describe Lumen as a native Apple-platform product.

The question is not whether to ship Lumen on the Mac; it is how. Three architectural paths exist, and they have materially different consequences for Mac HIG fit, platform-native behavior, maintenance burden, and future-proofing. Choosing among them is a load-bearing architectural decision that shapes every subsequent macOS PR.

## Decision

Add a second Xcode target, `Lumen-macOS`, to [`project.yml`](../../project.yml). Share Swift sources where they are cross-platform; gate UIKit-only and iOS-only APIs behind `#if os(iOS)` and a `PlatformAliases` utility layer (`PlatformImage`, `PlatformColor`, `PlatformFont`, `PlatformPasteboard`). Diverge at the application shell: `Window(id: "main")`, `NavigationSplitView`, a first-class `Settings {}` scene, `.commands { LumenCommands() }`, and `MenuBarExtra` on macOS; keep the existing iOS `WindowGroup` + tab shell untouched.

## Alternatives considered

- **Mac Catalyst.** Wrap the iOS app as a Mac app via UIKit-for-Mac. **Rejected because:**
  - Inherits iOS idioms (hamburger menus, iOS-styled controls) that a Mac user reads as non-native.
  - No real `Settings {}` scene — preferences collapse into an iOS-styled settings view.
  - Menu bar and `.commands` surface are second-class; Apple's own Catalyst apps (Messages, News) demonstrate the fidelity ceiling.
  - Apple's post-Sonoma investment trajectory has de-prioritized Catalyst relative to SwiftUI-on-macOS. Betting on it adds future risk without future reward.
- **Designed for iPad ("iPad app on Mac").** Zero-effort path: tick a box in Xcode. **Rejected because:**
  - Inherits every iOS idiom (touch targets, iOS-only toolbar placements, no menu bar).
  - No `Settings {}` scene, no `.commands` surface, no `MenuBarExtra`.
  - Acceptable for games and simple utilities; a productivity assistant that exposes no keyboard shortcuts or menu items reads as broken on the Mac.
- **Stay iOS-only.** Defer the Mac entirely. **Rejected because:**
  - Violates the stated product intent for a platform-spanning privacy-first assistant.
  - An assistant workflow is materially better on the Mac than on a phone; forgoing the surface has user-visible cost.
  - Weakens the multi-platform signal that [`README.md`](../../README.md) and [`docs/PORTFOLIO_AUTHORSHIP.md`](../PORTFOLIO_AUTHORSHIP.md) already imply.

## Consequences

- **Positive:**
  - Native Mac feel: real `Settings {}` scene, real menu-bar commands, real `MenuBarExtra`, a documented `NSStatusItem` escape hatch if SwiftUI's menu bar ever misbehaves.
  - Predictable behavior across OS updates — SwiftUI-on-macOS is Apple's first-party trajectory.
  - Clean boundary between iOS and macOS shells means future Apple-platform targets (visionOS, iPadOS-specific surfaces) plug into the same pattern.
- **Negative:**
  - Doubles the surface area for platform-specific bugs. Every PR that touches shared views now carries an implicit "does this still compile and behave on Mac?" question.
  - Requires a twelve-file UIKit/iOS-API audit to gate platform-specific code. The files live in `Lumen/Views/Shared/**` plus [`Lumen/Stores/SettingsStoreView.swift`](../../Lumen/Stores/SettingsStoreView.swift) — the last is a SwiftUI `View` despite its `Stores/` path, and is the one entry in the audit that is easy to miss with a naive `Views/Shared/**` grep.
  - Introduces a new `PlatformAliases` utility layer and a pasteboard shim for `NSPasteboard`. New contributors need to learn the pattern before touching shared views.
  - Voice input and camera attachment are deferred on the Mac at v1. Different auth model (`NSSpeechRecognizer`, sandbox entitlements for microphone) and different UX — this is a deliberate scope cut, not an oversight, and will be documented in the PR that ships the Mac target.
- **Neutral:**
  - Two sets of App Store screenshots and metadata from the first macOS release onward.
  - CI destination matrix grows by one (macOS) when the target lands.
  - [`docs/product/feature-parity-checklist.md`](../product/feature-parity-checklist.md) extends to cover Mac HIG items.

## Revisit trigger

Reassess this decision if **either** condition holds:

1. Apple ships a materially improved Mac Catalyst at a future WWDC — specifically, feature-set parity with SwiftUI-on-macOS on the `Settings {}` scene, `.commands`, and menu-bar fidelity — **and** Lumen's macOS-specific SwiftUI surface is under ~10% of the Mac codebase. At that point the maintenance argument for Catalyst might outweigh the HIG argument against it.
2. The two-platform maintenance burden exceeds ~20% of engineering time on a sustained three-month basis. At that point either the shared-sources strategy needs refactoring (not the native-target decision), or the Mac target's scope needs narrowing.

Absent either trigger, the decision stands.

## References

- [`0000-record-architecture-decisions.md`](0000-record-architecture-decisions.md) — the meta-ADR establishing this practice.
- [`docs/product/feature-parity-checklist.md`](../product/feature-parity-checklist.md) — the operational definition of "native platform feel" Lumen is held to; the Mac target will extend this checklist with macOS HIG items.
- Repo-grounding pass (2026-04-16): verified [`Lumen/Intents/`](../../Lumen/Intents/) contains only `import AppIntents` (cross-platform, macOS 13+) and therefore stays in the Mac target; [`Lumen/Extensions/SyntaxHighlighter.swift`](../../Lumen/Extensions/SyntaxHighlighter.swift) already uses `#if canImport(UIKit) / #elseif canImport(AppKit)` guards and needs no audit entry; the twelve-file `topBar*` / `navigationBarTitleDisplayMode` audit includes [`Lumen/Stores/SettingsStoreView.swift`](../../Lumen/Stores/SettingsStoreView.swift) despite its non-`Views/Shared/**` path.
- Follow-on ADR-0002 will document the macOS 15 deployment-target choice and will be co-located with the `project.yml` PR that creates the `Lumen-macOS` target, so the deployment decision's evidence lives next to the code change it governs.
