# Changelog

All notable changes to Lumen are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow the App Store build number. Dates are release-tag dates.

---

## [1.0.0] — 2026-04-15

First public release on TestFlight.

### Added

- **On-device AI** via Apple `FoundationModels` framework (Apple Intelligence); no account or setup required.
- **Ollama Local provider** — bring your own local server; bearer token stored in Keychain.
- **Ollama Cloud provider** — user-supplied API key, also stored in Keychain; never logged or transmitted by the developer.
- **Conversation history** — searchable, jump-to-message, edit-and-retry any prompt without losing context.
- **SwiftData persistence** for conversations and memories; on-device only, removed on uninstall.
- **Memories** — persist key details across conversations; user-controlled, categorised, and relevance-ranked.
- **Document import** — add PDFs, Markdown, and plain text to a conversation for local context.
- **Voice input** via on-device `Speech` framework; microphone permission requested only when invoked.
- **Agent tools** — small built-in utilities the model can invoke within a conversation.
- **Block-level Markdown rendering** in assistant replies (code blocks, headings, lists, inline code).
- **Dynamic Type and accessibility** audit across all core iOS flows.
- **iOS 26 Liquid Glass** compliance for all interactive surfaces.
- **First-class provider selection** UI for Apple Intelligence and Ollama.
- **Release screenshot capture harness** for App Store submission.
- **105-test suite** (unit + integration) running under Swift Testing and XCTest.
- **Swift 6 strict concurrency** enabled throughout.
- **GitHub Actions CI** — build, unit tests, `actionlint`, no-tabs, and workflow-sanity checks required for every merge.
- **WidgetKit extension** target (bundle ID prefix reserved for future widget work).

### Changed

- Provider selection refactored to a dedicated settings surface; previous single-toggle removed.
- Chat message actions tightened: long-press menu pruned to copy, retry, and delete.
- App Store export workflow hardened; archive and export scripts moved to `Scripts/`.

### Fixed

- Launch screen polish and agent output hygiene (excess whitespace, stray tool-call artifacts).
- Block Markdown not rendering in assistant replies on first load.

---

[1.0.0]: https://github.com/eulicesl/lumen/releases/tag/1.0.0
