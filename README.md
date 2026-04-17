# Lumen

**Private, native AI assistant for iPhone and iPad.** Apple Intelligence on-device by default, optional Ollama Local or Ollama Cloud for users who bring their own model endpoint. No developer-operated backend, no analytics pipeline, no tracking.

![iOS](https://img.shields.io/badge/iOS-26%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-26-0055FF?logo=swift&logoColor=white)
![Build](https://github.com/eulicesl/lumen/actions/workflows/ci.yml/badge.svg?branch=main)
![TestFlight](https://img.shields.io/badge/TestFlight-Public%20Beta-0a84ff)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-lightgrey)

> [!NOTE]
> Lumen is closed-source commercial software. The repository is public for portfolio, review, and reference purposes. See [LICENSE](LICENSE) for permitted use.

---

## What Lumen is

Lumen is a privacy-first AI assistant built from the ground up for Apple platforms. It treats the iPhone as the system of record and the on-device model as the default: your conversations, memories, and preferences stay on your device. Optional cloud providers (Ollama Local on your network, Ollama Cloud under your own account) exist for users who want them but are never required.

### Core capabilities

- **On-device chat** — Apple Intelligence via the `FoundationModels` framework, no account or setup.
- **Optional Ollama providers** — bring your own local server or Ollama Cloud API key.
- **Conversation history** — searchable, jump-to-message, edit-and-retry any prompt without losing context.
- **Document import** — add PDFs, markdown, and plain text to a conversation for local context.
- **Voice input** — on-device speech recognition, microphone-permission only when invoked.
- **Memories** — persist key details from a conversation for re-use in future chats.
- **Agent tools** — small built-in utilities the model can call within a conversation.

### What's explicitly missing by design

- No developer backend. There is no server that Lumen operates, no analytics pipeline, no crash reporter phoning home, no advertising SDK.
- No user accounts. There is nothing to sign up for.
- No cloud mirror of your conversations. Uninstalling the app removes every trace of Lumen-owned state.

---

## Tech stack

| Layer | Choice | Notes |
|---|---|---|
| UI | SwiftUI (iOS 26) | Native, SwiftUI-first. Uses Liquid Glass, Dynamic Type, and accessibility primitives. |
| Language | Swift 6 | Strict concurrency enabled. |
| Persistence | SwiftData | On-device only. Required-reason API declarations in `PrivacyInfo.xcprivacy`. |
| On-device AI | `FoundationModels` | Apple Intelligence generation, requires iOS 26 + supported hardware. |
| Remote AI (optional) | Ollama (self-hosted or Cloud) | User-supplied URL or API key, stored in Keychain. |
| Speech | Native `Speech` framework | On-device recognition. |
| Widget | WidgetKit | Shares bundle ID prefix for future extension-group work. |
| Testing | Swift Testing + XCTest | Unit + UI tests run per PR in GitHub Actions. |
| CI | GitHub Actions | `iOS Build + Tests`, `actionlint`, `no-tabs`, workflow sanity — all required for merge to main. |
| Code review | CodeRabbit + Gemini + Codex | Automated review passes plus branch-protection-enforced required checks. |

---

## Engineering practices

The repository is maintained to a deliberate "portfolio-grade" bar captured in [`docs/ENGINEERING_STANDARD.md`](docs/ENGINEERING_STANDARD.md). In practice that means:

- **Branch protection on `main`** — direct pushes blocked, linear history enforced, all required status checks must pass, review conversations must be resolved.
- **Every change ships through a PR** — properly-named branches (`feature/`, `fix/`, `chore/`, `release/`), conventional-commit-style messages, scoped test plans.
- **CI on every PR** — build, lint, tests, workflow sanity. Failure blocks merge.
- **Automated code review bots** — CodeRabbit and Gemini read every diff. Codex posts suggestions. Findings are triaged, addressed, and resolved before merge.
- **Test coverage tracked per PR** — the test target is wired into the Xcode project explicitly; adding a test file that isn't registered is treated as a real bug, not a silent miss.
- **Release discipline** — every shipped build maps to a single squash-merge commit on `main`, and the build number is bumped in one place (variable substitution from `$(CURRENT_PROJECT_VERSION)` in `Info.plist`, driven by `project.pbxproj`).

If you're reading this repo to evaluate how I work: the commit history on `main` and the closed PRs are the artifact.

---

## Privacy

Lumen's privacy posture is the product. See [`https://eulicesl.github.io/lumen-legal/`](https://eulicesl.github.io/lumen-legal/) for the live policy. Short version:

- **Collected by the developer:** nothing.
- **Linked to user identity:** nothing, except when the user opts into Ollama Cloud, in which case requests carry the user's own Ollama Cloud API key and go to `https://ollama.com`. The Lumen developer never sees that traffic.
- **Tracking:** none.
- **Third-party SDKs:** none.
- **Required-reason APIs** (declared in `Lumen/Resources/PrivacyInfo.xcprivacy`): `UserDefaults` (`CA92.1`), `FileTimestamp` (`3B52.1`), `DiskSpace` (`E174.1`). All three are for app-scoped on-device storage.

---

## Repository layout

```
.
├── Lumen/                      ← main app target (SwiftUI)
│   ├── Extensions/             ← small language-level extensions
│   ├── Models/                 ← value types and domain models
│   ├── Resources/              ← Info.plist, PrivacyInfo.xcprivacy, assets
│   ├── Services/               ← AI providers, agent loop, tool extraction
│   ├── Stores/                 ← chat store, memory store, preferences
│   ├── Utilities/              ← haptic engine, syntax highlighter, helpers
│   └── Views/                  ← SwiftUI views, grouped by surface
├── LumenTests/                 ← Swift Testing + XCTest unit coverage
├── LumenUITests/               ← XCUITest end-to-end flows
├── LumenWidget/                ← WidgetKit extension
├── Scripts/                    ← build, archive, export, screenshot capture
├── docs/                       ← engineering + product + release docs
│   ├── ENGINEERING_STANDARD.md ← the bar for this repo
│   ├── PORTFOLIO_AUTHORSHIP.md ← authorship and AI-tool disclosure
│   ├── product/                ← PRD, feature parity, sprint docs
│   └── release/                ← submission checklists and runbooks
├── exportOptions-appstore.plist
├── Lumen.xcodeproj             ← canonical; open this in Xcode
└── project.yml                 ← legacy XcodeGen spec (removal planned; see docs/ENGINEERING_STANDARD.md)
```

---

## Building locally

### Prerequisites

- macOS on Apple silicon
- Xcode 26 or later
- An iPhone or iPad simulator running iOS 26 (Xcode will install one on first launch)
- `xcodegen` (optional, only if you maintain the legacy `project.yml`—see `docs/ENGINEERING_STANDARD.md`): `brew install xcodegen`

### Open the project

```bash
git clone https://github.com/eulicesl/lumen.git
cd lumen
open Lumen.xcodeproj
```

### Build and test from the command line

```bash
# Build for a simulator (substitute the simulator UDID from `xcrun simctl list`)
xcodebuild build \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -destination "id=<simulator-udid>"

# Run the full test suite
xcodebuild test \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -destination "id=<simulator-udid>"
```

### Release pipeline

```bash
# Archive
xcodebuild archive \
  -project Lumen.xcodeproj \
  -scheme Lumen \
  -configuration Release \
  -archivePath build/Lumen.xcarchive \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates

# Export for App Store distribution
./Scripts/export_app_store_archive.sh

# Upload to App Store Connect (requires an API key at
# ~/.appstoreconnect/private_keys/AuthKey_<keyID>.p8)
xcrun altool --upload-app --type ios \
  --file build/app-store-export/Lumen.ipa \
  --apiKey <keyID> --apiIssuer <issuerID>
```

See [`TESTFLIGHT_RELEASE_PROCESS.md`](TESTFLIGHT_RELEASE_PROCESS.md) and [`docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md`](docs/release/FINAL_APP_STORE_RELEASE_CHECKLIST.md) for the full submission runbook.

---

## TestFlight

- **Public beta link:** https://testflight.apple.com/join/v8mYExkK (build 1.0.0, currently in Apple beta review for external testing)
- **Internal testers:** added by email through App Store Connect, install immediately
- **Privacy policy:** https://eulicesl.github.io/lumen-legal/

---

## Authorship

Lumen is original work by Eulices Lopez and was built from scratch in this repository as a native Apple-platform product. It is not a fork, a clone, or a white-label template.

AI tooling (Claude Code, Codex, CodeRabbit, Gemini Code Assist) was used as an engineering aid for implementation speed, code review coverage, and documentation refinement. Product direction, technical judgment, architectural decisions, code ownership, and final quality decisions rest with Eulices.

For the long-form statement and disclosure, see [`docs/PORTFOLIO_AUTHORSHIP.md`](docs/PORTFOLIO_AUTHORSHIP.md).

---

## Contributing

This is a closed-source commercial project, so unsolicited pull requests are not accepted. Bug reports and feedback through TestFlight are welcome. See [`SECURITY.md`](SECURITY.md) for responsible disclosure of security issues.

Internal contributors follow [`docs/WORKFLOW.md`](docs/WORKFLOW.md) and [`docs/PR_REVIEW_STANDARD.md`](docs/PR_REVIEW_STANDARD.md).

---

## License

Copyright © 2026 Eulices Lopez. All rights reserved. See [`LICENSE`](LICENSE) for the full proprietary terms. No permission is granted to use, modify, or redistribute this source without prior written authorization.

For licensing inquiries: **leulices@gmail.com**
