# Validation Checklists

## Purpose
This document tracks the Apple-side/runtime validation required before merging visible UI, shell, and product-structure changes.

## Global Rules
- Do not merge visible UI or shell changes purely on code review if Apple-side runtime validation is still missing.
- Document what was validated and what was not.
- Prefer screenshots for visible changes where practical.
- If validation is blocked by environment limitations, leave the PR unmerged until the relevant check can be run.

---

## PR #4 — iOS Layout / Safe-Area Fix
### Goal
Validate that the tactical layout fix actually resolves the observed clipping/compression issues.

### Build
- [ ] Build in Xcode for iPhone simulator
- [ ] Build for physical device if available
- [ ] Confirm no compile/runtime regressions

### Chat empty state
- [ ] "What can I help with?" is not clipped
- [ ] content is vertically balanced, not top-crammed
- [ ] model subtitle displays correctly
- [ ] chat content no longer fights the composer/tab bar for space

### Input bar
- [ ] composer spacing still feels intentional
- [ ] no awkward bottom gap above tab bar/home indicator
- [ ] keyboard shown/hidden behavior is still correct

### Onboarding
- [ ] onboarding content is not vertically cramped
- [ ] bottom controls are fully visible
- [ ] small-screen iPhone layout looks correct

### Regression
- [ ] no obvious new spacing regressions on iPad/mac shared paths
- [ ] no dark/light mode visual regression

---

## PR #5 — iOS 26 Shell Modernization
### Goal
Validate that the shell modernization feels native and stable.

### Build
- [ ] Build in Xcode on iOS 26-capable target
- [ ] Confirm shell APIs compile and run as expected

### Tab shell
- [ ] tab bar minimizes on scroll correctly
- [ ] tab bar reappears naturally
- [ ] shell remains visually stable with glass effects

### Bottom accessory
- [ ] accessory appears during generation
- [ ] progress indicator renders correctly
- [ ] model label is correct
- [ ] stop button works

### Conversation picker
- [ ] sheet presentation works correctly
- [ ] dismissal is smooth
- [ ] no navigation-state bugs after dismissing

### Chat scrolling
- [ ] soft scroll-edge treatment feels correct
- [ ] no clipping/jank introduced

### Regression
- [ ] no broken tab/navigation behavior on iPhone
- [ ] no bad interaction with PR #4 when both are applied locally

---

## Task 001 — Settings Unification
### Goal
Validate that settings are truly unified and persistence behaves correctly.

### Build
- [ ] Build in Xcode for supported Apple targets
- [ ] Confirm no compile/runtime regressions in settings entry points

### Entry points
- [ ] iPhone settings tab routes to canonical settings surface
- [ ] iPad settings sheet routes to canonical settings surface
- [ ] macOS settings sheet routes to canonical settings surface

### Information architecture
- [ ] Models section present and usable
- [ ] Local Network / Ollama section present and usable
- [ ] Memory section present and usable
- [ ] Tools / Agent Mode section present and usable
- [ ] Appearance section present and usable
- [ ] Privacy section present and usable
- [ ] About section present and usable
- [ ] Data section present and usable

### Persistence
- [ ] model selection persists correctly
- [ ] Ollama enabled persists correctly
- [ ] Ollama server URL persists correctly
- [ ] Ollama bearer token persists correctly
- [ ] appearance/color scheme persists correctly

### Regression
- [ ] no duplicate old settings flow remains exposed
- [ ] compatibility wrapper does not present divergent UI
- [ ] no major setting previously available is missing

---

## Ongoing Rule
Before merge, every visible UI/product change should either:
1. pass the relevant checklist, or
2. remain unmerged with the validation gap clearly documented.
