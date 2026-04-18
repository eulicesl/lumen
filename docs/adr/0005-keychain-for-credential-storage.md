# 0005: Keychain for credential storage

- **Status:** Accepted 2025-10-01
- **Date:** 2025-10-01
- **Deciders:** Eulices Lopez
- **Related:** [`0002-on-device-first-ai-with-apple-foundation-models.md`](0002-on-device-first-ai-with-apple-foundation-models.md), [`0004-no-backend-serverless-architecture.md`](0004-no-backend-serverless-architecture.md)

## Context

Lumen's optional Ollama providers require user-supplied credentials: a bearer token for Ollama Local and an API key for Ollama Cloud. These are secrets; storing them in UserDefaults writes them to a property list that is included in unencrypted iTunes backups, readable by any process with the app's container access, and visible in plaintext in crash logs and diagnostics. A migration was also needed: an early build stored the bearer token in UserDefaults before the Keychain path existed.

## Decision

We will store all credentials exclusively in the iOS Keychain via a `SecretStore` protocol backed by `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete`. UserDefaults is used only for non-sensitive preferences. At `AppStore` initialisation, any legacy token found in UserDefaults is migrated to Keychain and the UserDefaults entry is deleted.

## Alternatives considered

- **UserDefaults with obfuscation** — Base64-encode or XOR the token before writing. **Rejected because:** obfuscation is not encryption; the key is in the binary, making it trivially reversible. App Store review guidance and Apple's own HIG explicitly call out Keychain as the correct storage for secrets.
- **Encrypted file in app sandbox** — write a small encrypted file, store the encryption key in Keychain. **Rejected because:** this adds a key-wrapping layer with no benefit; the Keychain already provides hardware-backed encryption on supported devices (Secure Enclave). Adding a file is pure overhead.
- **Leave in UserDefaults** — simplest code path. **Rejected because:** bearer tokens and API keys are credentials. Storing them in UserDefaults violates Apple's data storage guidelines and exposes them to unencrypted backup exfiltration.

## Consequences

- **Positive:** Credentials are hardware-encrypted on Secure Enclave devices. They are excluded from unencrypted backups by default Keychain accessibility settings. The `SecretStore` protocol allows `InMemorySecretStore` in tests without touching the real Keychain.
- **Negative:** Keychain access can fail at runtime (e.g., device locked, Keychain corrupted). Callers must handle errors; the `SecretStore` protocol uses `throws` throughout.
- **Neutral:** Keychain items survive app uninstall on iOS by default; the app deletes its Keychain items on first launch after re-install if it detects a fresh install state.

## Revisit trigger

If Apple introduces a new credential storage API (e.g., a dedicated `CredentialStore` framework) that supersedes `SecItem` with better ergonomics and equivalent security guarantees, migrate at that point.

## References

- [`LumenTests/MemoryStoreTests.swift`](../../LumenTests/MemoryStoreTests.swift) — `AppStoreSecurityTests` suite verifies migration and secure-only storage.
- Apple Security framework documentation: `SecItemAdd`, `SecItemCopyMatching`, `kSecAttrAccessibleWhenUnlocked`.
- [`Lumen/Resources/PrivacyInfo.xcprivacy`](../../Lumen/Resources/PrivacyInfo.xcprivacy) — `UserDefaults` declared for app-scoped non-sensitive preferences only (`CA92.1`).
