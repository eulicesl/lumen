# Lumen Feature Parity Checklist

Status legend: `Done` | `In Progress` | `Not Started` | `Blocked`

## Apple HIG / Platform Compliance
- [x] iPhone conversation picker uses sheet-based presentation.  
  - Priority: P1  
  - Status: Done
- [x] Success confirmation haptic after assistant response starts/completes.  
  - Priority: P2  
  - Status: Done
- [ ] Dynamic Type audit and scaling completeness.  
  - Priority: P0  
  - Status: Not Started
- [ ] Accessibility labels/hints/values audit for all critical controls.  
  - Priority: P0  
  - Status: In Progress
- [ ] Reduce Motion consistency across symbol effects and animated transitions.  
  - Priority: P1  
  - Status: Not Started
- [ ] Settings primary page large title mode.  
  - Priority: P1  
  - Status: Not Started
- [ ] Pull-to-refresh for conversations and model list.  
  - Priority: P1  
  - Status: Not Started
- [ ] Scene state restoration (selected conversation/context/tab).  
  - Priority: P1  
  - Status: Not Started

## ChatGPT Core Parity
- [ ] True message edit with branch-aware regeneration timeline.  
  - Priority: P0  
  - Status: Not Started
- [ ] Full-text search across message history.  
  - Priority: P0  
  - Status: Not Started
  - Notes: Implement against the existing hydrated conversation/message model first; add indexing only if profiling shows it is necessary.
- [ ] File upload pipeline (PDF/text/code/docs), not image-only.  
  - Priority: P0  
  - Status: Not Started
- [ ] Starter prompts/suggested replies for empty chat states.  
  - Priority: P1  
  - Status: Not Started
- [ ] Scroll-to-bottom affordance for long conversations.  
  - Priority: P1  
  - Status: Not Started
- [ ] Copy feedback UX for code blocks and message copy actions.  
  - Priority: P1  
  - Status: Not Started

## Claude Core Parity
- [ ] Enhanced thinking UX (streaming/distinctive reasoning display).  
  - Priority: P1  
  - Status: Not Started
- [ ] Artifacts rendering pipeline (HTML/SVG/structured outputs).  
  - Priority: P1  
  - Status: Not Started
- [ ] Projects with persistent shared context.  
  - Priority: P1  
  - Status: Not Started

## Security / Reliability
- [ ] Ollama bearer token moved from `UserDefaults` to Keychain + migration.  
  - Priority: P1  
  - Status: Not Started
- [ ] Improved user-facing error surfaces + retry paths.  
  - Priority: P1  
  - Status: Not Started
- [ ] Network reachability/status indicator for Ollama connectivity.  
  - Priority: P1  
  - Status: Not Started

## Sprint Mapping
- Sprint 01: P0 parity trio (edit/regenerate, full-text search, doc uploads)
- Sprint 02: HIG + accessibility fundamentals
- Sprint 03: UX parity polish (suggestions, scroll affordance, copy feedback, thinking UX)
- Sprint 04: Security + reliability (Keychain, network state, retry UX)

## Execution Notes
- Preserve current regenerate behavior for the most recent assistant response while extending the model to support edit-from-history.
- Preserve the existing user-message "Edit & Resend" affordance as the transitional baseline, not the end state.
