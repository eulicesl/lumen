# 0002: On-device-first AI with Apple FoundationModels

- **Status:** Accepted 2025-10-01
- **Date:** 2025-10-01
- **Deciders:** Eulices Lopez
- **Related:** [`0004-no-backend-serverless-architecture.md`](0004-no-backend-serverless-architecture.md), [`0005-keychain-for-credential-storage.md`](0005-keychain-for-credential-storage.md)

## Context

Lumen's core proposition is a privacy-first AI assistant. The design question is which AI runtime to target by default and how to handle hardware or availability gaps. Three layers exist: on-device via Apple's `FoundationModels` framework (Apple Intelligence), self-hosted via Ollama Local, and cloud-hosted via Ollama Cloud. The default matters: it determines whether user data ever leaves the device at all.

## Decision

We will default to Apple `FoundationModels` (on-device inference) with zero user configuration required. Ollama Local (user-supplied server URL + optional bearer token) and Ollama Cloud (user-supplied API key) are opt-in, secondary providers. Credentials for optional providers are stored in Keychain, not UserDefaults. The app functions without any provider setup on hardware that supports Apple Intelligence.

## Alternatives considered

- **Default to Ollama Cloud** — simplest to support any device, but requires an API key at first launch and sends every message to a third-party server. **Rejected because:** it contradicts the privacy-first positioning; a privacy product that phones home by default is not a privacy product.
- **Core ML custom model** — bundle a quantized model in the app, no Apple Intelligence dependency. **Rejected because:** bundle size (2–4 GB) is prohibitive for App Store distribution, and Apple Intelligence inference quality exceeds what fits in a shippable binary.
- **OpenAI or Anthropic as default** — largest capability ceiling. **Rejected because:** requires an API key, costs money per request, and sends all conversation content to a developer-operated server — the antithesis of the privacy goal.

## Consequences

- **Positive:** Zero-setup experience on supported hardware. No conversation content ever leaves the device by default. Privacy policy is trivially true: the developer receives nothing.
- **Negative:** Apple Intelligence requires iOS 18.1+ on iPhone 15 Pro / M1 iPad or newer. Users on older hardware must configure a provider or see a capability-unavailable state.
- **Neutral:** Fallback provider selection UI is required; it is a first-class surface, not an afterthought.

## Revisit trigger

If Apple deprecates or materially restricts the `FoundationModels` API, or if model quality regresses significantly on a major iOS release, revisit whether a bundled Core ML model or a mandatory cloud provider is a better default.

## References

- [`0004-no-backend-serverless-architecture.md`](0004-no-backend-serverless-architecture.md) — explains why there is no developer-operated fallback server.
- [`0005-keychain-for-credential-storage.md`](0005-keychain-for-credential-storage.md) — covers credential storage for optional providers.
- Apple `FoundationModels` framework documentation (WWDC 2025).
