# Lumen Product Requirements Document (Execution Edition)

**Version:** 1.1  
**Last Updated:** March 31, 2026  
**Status:** Active

## 1) Objective
Lumen is a privacy-first, native Apple-platform AI assistant targeting feature parity with core ChatGPT and Claude workflows while preserving Apple-grade design quality, accessibility, and performance.

## 2) Current State Snapshot (code-verified on `main` @ `b1b04f2`)
### Completed / no longer backlog
- iPhone conversation picker uses `.sheet` (no longer `fullScreenCover`).
- Success confirmation haptic on response completion is implemented.
- True branch-aware edit/regenerate from message history is implemented.
- Full-text search across message history is implemented.
- Local document import supports PDF and text-based files.
- Scroll-to-bottom affordance for long conversations is implemented.

### Remaining top gaps
#### P0
- Dynamic Type audit and scaling completeness.
- Accessibility labels/hints/values audit for critical controls.

#### P1
- Settings primary screen should use large title mode.
- Pull-to-refresh on conversation/model surfaces.
- Reduce Motion behavior completion across symbol-heavy views.
- Starter prompts/suggested replies for empty chats.

### Current behavior to preserve while closing parity gaps
- Preserve the shipped latest-turn regenerate flow while improving adjacent UX.
- Preserve the shipped branch-aware edit-from-history behavior while layering follow-on parity work such as suggestions and artifacts.

## 3) Product Principles
1. Privacy by default (local/on-device and user-controlled infra).
2. Native-first UX that follows Apple platform conventions.
3. Streaming-first responsiveness and reliability.
4. Accessibility and motion sensitivity support as first-class requirements.
5. Incremental, testable delivery via small PRs.

## 4) Sprint Strategy
We execute via micro PRDs (one per sprint/theme):
- Sprint 01: Core P0 parity foundation
- Sprint 02: HIG + Accessibility hardening
- Sprint 03: Input/Output parity and UX polish
- Sprint 04: Security + reliability completion

## 5) Definition of Done (global)
A feature is complete only when:
- Acceptance criteria are fully met.
- Unit/integration checks pass locally/CI.
- Accessibility and motion requirements are verified where applicable.
- Master parity checklist status is updated.
- PR includes rationale, test evidence, and rollout/risk notes.

## 6) Execution Artifacts
- Master checklist: `docs/product/feature-parity-checklist.md`
- Sprint micro PRDs: `docs/product/sprints/`
- Design doc target path: `docs/design/design.md` (currently a pointer until the source content is migrated)
