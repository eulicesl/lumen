# Lumen Review Queue

## Purpose
Track the validation and merge progression for open Lumen PRs in a clean, reviewer-friendly order.

## Status key
- **Not validated** — code is reviewable but still waiting on Apple-side/runtime validation
- **Validated** — Apple-side/runtime validation completed successfully
- **Ready to merge** — validated and approved for merge
- **Merged** — already landed

---

## Review / Validation Order

### 1. PR #4 — Tactical layout / safe-area fix
- **Status:** Not validated
- **Why first:** smallest visible UI fix, lowest conceptual complexity, best baseline for later shell work
- **Validation source:** `docs/VALIDATION_CHECKLISTS.md`
- **Merge condition:** layout issue is fixed and no safe-area regressions appear

### 2. PR #5 — iOS 26 shell modernization
- **Status:** Not validated
- **Why second:** shell behavior should be reviewed after the tactical layout fix is understood
- **Validation source:** `docs/VALIDATION_CHECKLISTS.md`
- **Merge condition:** shell behavior feels native and stable

### 3. PR #8 — Settings unification
- **Status:** Not validated
- **Why third:** broader product-structure change; should be validated after shell/layout confidence is established
- **Validation source:** `docs/VALIDATION_CHECKLISTS.md`
- **Merge condition:** all settings entry points unify correctly and persistence behaves correctly

### 4. PR #9 — Export conversations
- **Status:** Not validated
- **Why fourth:** self-contained trust feature; easier to validate after settings structure is stable
- **Validation source:** `docs/VALIDATION_CHECKLISTS.md`
- **Merge condition:** JSON and Markdown export both work as expected and share flows behave correctly

### 5. PR #10 — Permission hardening
- **Status:** Not validated
- **Why fifth:** requires the most tedious runtime/device validation across denied states and recovery flows
- **Validation source:** `docs/VALIDATION_CHECKLISTS.md`
- **Merge condition:** permission states are explicit, recoverable, and do not fail silently

---

## Merge Order
If validation passes cleanly, merge in this order:
1. PR #4
2. PR #5
3. PR #8
4. PR #9
5. PR #10

---

## Notes
- Do not merge these PRs purely on code review if Apple-side/runtime validation is still missing.
- Visible UI and shell changes require real Apple-side validation before merge.
- Update this file as validation progresses so the repo itself reflects review state.
