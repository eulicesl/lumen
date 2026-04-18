# 0004: No backend / serverless architecture

- **Status:** Accepted 2025-10-01 (retrospective — decision predates the ADR practice; recorded 2026-04-18)
- **Date:** 2025-10-01
- **Deciders:** Eulices Lopez
- **Related:** [`0002-on-device-first-ai-with-apple-foundation-models.md`](0002-on-device-first-ai-with-apple-foundation-models.md), [`0005-keychain-for-credential-storage.md`](0005-keychain-for-credential-storage.md)

## Context

Most AI assistants require a developer-operated backend: for proxying model API calls, storing conversation history server-side, syncing state across devices, or gating access behind accounts. Each of these choices creates a data liability: the developer receives conversation content, can be compelled to produce it under a legal process, and is a high-value breach target. Lumen's stated privacy posture is that the developer collects nothing.

## Decision

We will operate no developer-controlled server. There is no API proxy, no analytics pipeline, no crash reporter, no sync backend, and no account system. All state lives on the user's device. Optional Ollama providers connect directly from the app to the user's own endpoints; the developer never sees that traffic.

## Alternatives considered

- **Backend API proxy for Ollama Cloud** — hide the user's API key server-side, handle key rotation centrally. **Rejected because:** it requires the developer to receive every request, which is the exact data liability we are eliminating. The user's API key is their credential and should stay on their device.
- **CloudKit sync** — iCloud-backed conversation history across devices, no developer server required. **Rejected because:** it is an additive feature, not a core requirement for v1. It remains a viable future addition under this ADR (CloudKit is Apple-operated, not developer-operated).
- **Firebase / Supabase** — hosted backend with generous free tiers, fast to bootstrap. **Rejected because:** introduces a third-party data processor with server-side conversation storage — the opposite of privacy-by-design.

## Consequences

- **Positive:** Developer collects zero user data. Privacy policy is trivially verifiable. No server cost, no server reliability SLA, no GDPR/CCPA data subject request surface.
- **Negative:** No cross-device sync at v1. If a user loses their device or restores from backup, conversation history depends on iCloud device backup (user-controlled, not developer-controlled).
- **Neutral:** App Store review does not require a backend justification. TestFlight distribution works with zero server infrastructure.

## Revisit trigger

If the product adds a collaboration feature (shared conversations, team workspaces) that fundamentally requires a server, revisit this decision with a privacy impact assessment before any backend work begins.

## References

- [`Lumen/Resources/PrivacyInfo.xcprivacy`](../../Lumen/Resources/PrivacyInfo.xcprivacy) — required-reason API declarations; no network-access entries because there is no developer-operated endpoint.
- [`README.md`](../../README.md) — "No developer backend" in the privacy section.
- [`docs/PORTFOLIO_AUTHORSHIP.md`](../PORTFOLIO_AUTHORSHIP.md) — authorship and AI-tool disclosure.
