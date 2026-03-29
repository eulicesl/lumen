# Lumen Roadmap

## Purpose
This roadmap translates the Lumen PRD and design rules into an execution order optimized for:
- App Store readiness
- professional product quality
- portfolio strength
- parallel execution in small PRs

---

## Phase 1 — App Store Foundations
### 1. Settings unification
**Goal:** Merge duplicate settings surfaces into one coherent settings experience.
- unify `SettingsView` / `SettingsStoreView`
- define final settings information architecture
- reduce product drift and confusion

**Complexity:** Medium
**Priority:** Critical

### 2. Export conversations
**Goal:** Add user-owned export in JSON and Markdown.
- conversation export actions
- share sheet integration
- format/versioning decisions

**Complexity:** Medium
**Priority:** Critical

### 3. Permission hardening + App Review readiness
**Goal:** Ensure denied permissions and review-sensitive flows are graceful.
- permission-denied UX
- recovery paths to Settings
- internal App Review checklist
- metadata/privacy text audit

**Complexity:** Small–Medium
**Priority:** Critical

### 4. Accessibility pass
**Goal:** Reach a credible accessibility and polish baseline.
- VoiceOver labels/hints
- Dynamic Type review
- Reduce Motion handling
- focus and action discoverability review

**Complexity:** Medium
**Priority:** Critical

### 5. Test/release confidence
**Goal:** Raise confidence in shipping.
- add UI smoke tests
- expand targeted unit tests
- align CI with real ship-critical paths

**Complexity:** Medium
**Priority:** Critical

### 6. Product/support presentation
**Goal:** Make Lumen legible as a product.
- README/product positioning refresh
- support/privacy/public docs
- screenshots/demo plan
- App Store asset checklist

**Complexity:** Small
**Priority:** Critical

---

## Phase 2 — Professional Product Maturity
### 7. Conversation tags + lightweight filters
**Goal:** Improve organization without overbuilding.
- tags
- filter chips
- search/filter integration

**Complexity:** Medium
**Priority:** High

### 8. Provider/tooling architecture cleanup
**Goal:** Make the internals more extensible and professional.
- provider/service abstraction improvements
- reduce brittle prompt-pattern logic
- cleaner execution boundaries

**Complexity:** High
**Priority:** High

### 9. Foundation Models-native enhancements
**Goal:** Increase Lumen’s Apple-native differentiation.
- smarter summaries/helpers
- structured generation surfaces
- model-aware UX improvements

**Complexity:** Medium–High
**Priority:** High

### 10. Import / restore
**Goal:** Complete the portability story after export lands.
- restore path
- validation and safety
- migration/version handling

**Complexity:** Medium
**Priority:** High

---

## Phase 3 — Portfolio & Premium Polish
### 11. Portfolio-native visual polish
- improved empty states
- guided sample prompts
- better first-run/demo experience
- visual consistency pass

**Complexity:** Small–Medium
**Priority:** Medium

### 12. Advanced prompt library improvements
- reusable variables/templates
- richer prompt presentation
- stronger demo value

**Complexity:** Small–Medium
**Priority:** Medium

### 13. Optional advanced iOS features
- live activities / background coordination
- deeper Assistive Access work
- carefully chosen native enhancements

**Complexity:** Medium
**Priority:** Medium

---

## Avoid / Defer
These should not block 1.0:
- feature-flag-heavy sprawl
- full Enchanted parity
- deep folder trees
- desktop/mac-only power-user features as priority work
- cross-platform sprawl
- expanding beyond the local-first product story without clear reason

---

## PR Sequencing Recommendation
1. Settings unification
2. Export conversations
3. Permission/App Review hardening
4. Accessibility pass
5. Test expansion / UI smoke tests
6. Product/support/docs assets
7. Tags + filters
8. Provider/tooling cleanup
9. Foundation Models-native enhancements
10. Import/restore
