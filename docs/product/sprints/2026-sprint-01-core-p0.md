# Micro PRD — Sprint 01: Core P0 Parity

## Goal
Deliver the three highest-impact parity blockers: message edit/regenerate correctness, full-text search, and document uploads.

## In Scope
- True edit-from-message flow with branch-aware regenerate behavior.
- Search over full message content using the current hydrated conversation/message data model; add indexing only if the simple path fails scale or latency targets.
- Non-image file uploads (PDF/text/code/docs) with extraction + attachment UX.

## Out of Scope
- Artifact rendering.
- Projects model.
- Advanced voice mode.

## Acceptance Criteria
- [ ] User can edit a past user message and regenerate from that point.
- [ ] Search returns matches from message history, not just conversation metadata.
- [ ] Users can attach at least PDF + plain text + source files and send successfully.
- [ ] Error states for unsupported/oversized files are user-friendly.

## Engineering Notes
- Touch points: `MessageBubbleView`, `ChatStore`, `SearchView`, `ChatView`, `DataService`, `InputBarView`, `ChatMessage`, file extraction service.
- Ensure backward-compatible data model evolution for attachments.
- Do not introduce persistence or schema complexity for search until the current in-memory/hydrated approach is proven insufficient.

## Current Behavior To Preserve
- `ChatStore.regenerate()` already supports regenerating the most recent assistant response and should continue to work unchanged for the latest-turn case.
- `MessageBubbleView` already exposes "Edit & Resend" for user messages; Sprint 01 should evolve this into true edit-from-point behavior rather than removing the existing affordance.

## Verification
- Build succeeds for iOS target.
- Unit tests for search and edited-message timeline behavior.
- Manual scenario checks for mixed text + file attachments.
