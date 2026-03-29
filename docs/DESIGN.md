# Lumen Design & Engineering Principles

## Purpose
This document defines the architectural and UX rules for building Lumen into a professional, App Store-ready, portfolio-quality app.

## Core Design Principles
1. **Use platform-native APIs first.** Prefer Apple-native SwiftUI patterns over custom workarounds.
2. **Preserve local-first identity.** Features should reinforce privacy, trust, and on-device/local-network usage.
3. **Keep shells simple and composable.** Navigation, chat, settings, and onboarding should have clear boundaries.
4. **Minimize layout hacks.** Favor safe-area-aware composition, flexible layout, and adaptive spacing over hard-coded offsets.
5. **Ship reviewer-friendly changes.** Prefer small, focused PRs with clear intent.
6. **Port selectively from Enchanted.** Borrow maturity, not bloat.

## UX Principles
### iPhone-first
Lumen should optimize for iPhone first. iPad/macOS support may exist, but iPhone is the primary UX bar for App Store quality.

### iOS 26-native behavior
Where practical, use modern Apple patterns such as:
- `GlassEffectContainer`
- `safeAreaInset`
- `tabBarMinimizeBehavior`
- `tabViewBottomAccessory`
- `scrollEdgeEffectStyle`

Do not force iOS 26 behavior into places where it increases fragility. Prefer stable native behavior over novelty.

### Trust-first UX
Users must understand:
- what data is stored
- what permissions are required
- how to recover from denied permissions
- how to export or move their data

## Architectural Principles
### 1. Clear boundaries
- **App shell** owns navigation, tab structure, and global presentation.
- **Chat layer** owns message rendering, conversation state, and input orchestration.
- **Provider layer** owns model/provider communication details.
- **Services** own reusable external/system integration logic.
- **Stores** own app state and feature state, not view composition hacks.

### 2. Provider abstraction over prompt hacks
Where possible, move toward cleaner provider/service abstractions instead of brittle string-pattern tool protocols.

### 3. Privacy-first defaults
New features should default to local or user-controlled behavior. Cloud dependencies must be explicit and justifiable.

### 4. Settings coherence
There must be one canonical settings architecture. Duplicate settings surfaces should be unified rather than tolerated.

## Porting Policy from Enchanted
### Worth porting
- settings maturity and structure
- export/import foundations
- App Review/release hardening patterns
- accessibility improvements
- iOS 26 shell/navigation patterns
- lightweight conversation organization
- stronger product/support/privacy surface

### Port carefully / adapt
- provider architecture abstractions
- system integrations
- Foundation Models enhancements
- demo/presentation patterns

### Avoid porting wholesale
- feature-flag sprawl
- desktop/mac power-user extras as early priorities
- cross-platform ambition that delays App Store readiness
- anything that weakens Lumen’s simpler local-first story

## UI Rules
### Navigation shell
- keep tab shell stable and native
- avoid redundant fullscreen frames
- prefer modern iOS 26 tab behaviors where useful

### Chat layout
- content should flex naturally
- bottom controls should use safe-area-aware composition
- avoid top-pinned full-screen alignment hacks
- message list behavior should remain modular and testable

### Onboarding
- onboarding should feel roomy, legible, and not vertically cramped
- bottom controls belong in safe-area-aware layout
- the app’s privacy/local-first story must be immediately clear

### Settings
- one coherent information architecture
- sections should map to real user mental models:
  - Models
  - Local Network / Ollama
  - Privacy
  - Memory
  - Voice
  - Appearance
  - About / Support

## Quality Bar
A change is not done when code compiles. It is done when:
- layout is adaptive
- naming is coherent
- settings/UX remain understandable
- docs or reviewer notes explain intent if needed
- visible UI changes come with screenshots when possible
- permission/privacy implications are considered

## Review Rules
- prefer one concern per PR
- bugfix PRs and shell-modernization PRs should stay separate
- avoid mixing architecture refactors with UX polish unless tightly coupled
- do not open upstream-facing PRs prematurely when quality gates are not met

## App Store Readiness Rules
Before shipping broadly, ensure:
- privacy docs are clear
- support path exists
- permission recovery flows exist
- export exists
- accessibility pass has been completed
- release checklist is actually executable
