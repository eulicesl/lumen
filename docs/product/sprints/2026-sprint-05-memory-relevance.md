# Micro PRD — Sprint 05: Memory Relevance + Phase Gates

## Goal
Increase response relevance and control prompt growth by shifting memory injection from "all active memories" to a compact index + relevant subset.

## Why this matters
- Reduces prompt bloat as users store more memories.
- Improves personalization quality for the current request.
- Establishes measurable go/no-go criteria for more advanced memory work.

## Phase Plan

### Phase 1 (Ship now)
- Add prompt-aware relevance scoring in `MemoryStore`.
- Inject:
  1) compact memory index, and
  2) top-k relevant memory hints for current prompt.
- Keep implementation heuristic/simple (token overlap + light boosts).

### Phase 2 (Only if Phase 1 data supports it)
- Add background memory maintenance (dedupe + staleness cleanup) in an isolated service/actor.
- Keep user-facing behavior unchanged except quality improvements.

### Phase 3 (Optional, availability-gated)
- Add semantic relevance ranking (on-device where available, with fallback to Phase 1 heuristics).

## Acceptance Criteria (Phase 1)
- [x] Prompt assembly uses top-k relevant memory hints instead of dumping all memories.
- [x] Memory context includes compact index + relevant section.
- [x] Unit tests cover relevance ordering and prompt-scoped context assembly.

## Verification Plan

### Automated
- `MemoryStoreTests`:
  - relevant memories prioritize query overlap,
  - prompt-scoped context section includes only selected top-k hints,
  - disabled/inactive behavior unchanged.

### Manual
- Scenario A: coding request + mixed memories → coding-related memories appear in relevant section.
- Scenario B: lifestyle request + mixed memories → lifestyle memories appear.
- Scenario C: no meaningful overlap → safe fallback to recency order.

## Phase 2 / 3 Decision Gates
Evaluate after **7 days** or **>=100 user prompts** (whichever comes first):

### Continue to Phase 2 if ALL are true
- Relevance quality improved in spot checks.
- No regressions in response latency.
- No increase in memory-related bug reports.

### Continue to Phase 3 only if BOTH are true
- Phase 2 is stable in production-like use.
- Heuristic ranking still misses obvious relevance in real prompts.

## Revisit Mechanism (do not forget)
- Add this checkpoint to release readiness:
  - `docs/release/RELEASE_READINESS.md` → "Sprint 05 memory phase-gate review completed".
- Track decision in this file under "Decision Log" before starting Phase 2/3.

## Decision Log
- 2026-04-01: Phase 1 approved and implemented. Phase 2/3 pending gate review.