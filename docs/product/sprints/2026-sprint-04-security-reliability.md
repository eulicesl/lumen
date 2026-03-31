# Micro PRD — Sprint 04: Security + Reliability

## Goal
Close security and operational confidence gaps before wider rollout.

## In Scope
- Move Ollama bearer token to Keychain + migration from legacy defaults.
- Network status indication for model/server reachability.
- User-facing transient error surfacing + retry affordances.

## Acceptance Criteria
- [x] Token is persisted in Keychain and legacy defaults key is migrated/cleared.
- [x] User can quickly see when Ollama is unreachable.
- [x] Retry paths are available for common transient failures.

## Verification
- Migration test for existing installs.
- Offline/unreachable network scenarios validated.
- Error/retry flows manually verified.
