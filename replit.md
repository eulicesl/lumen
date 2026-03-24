# Lumen AI

A privacy-first, iOS 26 native AI assistant with Liquid Glass design, multi-provider support, and deep Apple ecosystem integration.

## Overview

Lumen is a native Swift/SwiftUI app targeting iOS 26, iPadOS 26, and macOS 26. It runs AI inference entirely on the user's own infrastructure — either Apple Intelligence (on-device) or Ollama (self-hosted). Zero cloud dependency, zero telemetry.

**Note:** This is a native Xcode project. All Swift source files live in `Lumen/`. To build and run, open the project in **Xcode 26** on macOS.

## Project Structure

```
Lumen/
├── App/                           # Entry point + AppDelegate
│   ├── LumenApp.swift             # @main, SwiftData model container
│   ├── AppDelegate.swift          # BGTasks, deep link handling
│   └── ContentView.swift          # Platform branch (iOS vs macOS)
├── DesignSystem/                  # Design tokens + reusable components
│   ├── LumenTokens.swift          # Spacing, radius, animation, type
│   ├── LumenColor.swift           # Semantic system colors
│   ├── LumenIcon.swift            # SF Symbol name constants
│   └── Components/
│       ├── GlassContainer.swift   # .glassEffect() wrapper with fallback
│       ├── LumenButton.swift      # Primary/secondary/destructive styles
│       └── LoadingIndicator.swift # TypingIndicator + StreamingPulse
├── Models/                        # Domain value types (Sendable, Codable)
│   ├── AIModel.swift              # AI model descriptor
│   ├── ChatMessage.swift          # Message with role, content, metadata
│   ├── Conversation.swift         # Conversation with messages + metadata
│   ├── ChatToken.swift            # Streaming token + ChatOptions
│   └── Enums/
│       ├── MessageRole.swift      # .user / .assistant / .system
│       ├── ConversationState.swift # .idle / .generating / .error
│       └── AIProviderType.swift   # .ollama / .foundationModels
├── Data/                          # Persistence layer
│   ├── SwiftData/
│   │   ├── ConversationSD.swift   # @Model with cascade messages
│   │   ├── MessageSD.swift        # @Model with externalStorage imageData
│   │   ├── AIModelSD.swift        # @Model for persisted model configs
│   │   └── Schema.swift           # VersionedSchema + migration plan
│   └── DataService.swift          # Actor-isolated CRUD, .forTesting()
├── Services/                      # Business logic layer (actors)
│   ├── Providers/
│   │   ├── AIProvider.swift       # Protocol: AIProvider: Actor
│   │   ├── OllamaProvider.swift   # Full Ollama API impl (NDJSON stream)
│   │   └── FoundationModelsProvider.swift  # Apple Foundation Models
│   └── AIService.swift            # Provider router + availability check
├── Stores/                        # @Observable state stores (MainActor)
│   ├── AppStore.swift             # Global: tab, settings, alerts
│   ├── ChatStore.swift            # Chat: messages, streaming, CRUD
│   └── ModelStore.swift           # Models: listing, selection
├── Views/
│   ├── Shared/                    # Cross-platform views (Phase 1+)
│   ├── iOS/
│   │   └── MainTabView.swift      # 5-tab TabView with .search role
│   └── macOS/
│       └── MacContentView.swift   # NavigationSplitView + toolbar
├── Extensions/
│   ├── Date+Grouping.swift        # Today/Yesterday/7 days grouping
│   └── String+Markdown.swift      # Markdown helpers + think-block parsing
└── Resources/
    └── Info.plist                 # Permissions + background tasks

LumenTests/
├── DataServiceTests.swift         # 8 tests: CRUD, pin, system prompt
└── AIProviderMock.swift           # MockAIProvider actor + UnavailableProvider
```

## Architecture

```
UI Layer (SwiftUI Views)
        ↓
Store Layer (@Observable, @MainActor)
  AppStore · ChatStore · ModelStore
        ↓
Service Layer (Actor-isolated)
  AIService → OllamaProvider / FoundationModelsProvider
  DataService (SwiftData CRUD)
        ↓
Data Layer (SwiftData)
  ConversationSD · MessageSD · AIModelSD
```

### Key Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Language | Swift 6, `-strict-concurrency=complete` | Catches threading bugs at compile time |
| UI | SwiftUI (iOS 26 APIs) | Native, Liquid Glass, declarative |
| Persistence | SwiftData | Native, iCloud-ready, SwiftUI-integrated |
| State | `@Observable` | Modern replacement for `ObservableObject` |
| Services | `actor` isolation | Thread-safe, no DispatchQueue |
| Testing | Swift Testing (`@Test`, `@Suite`, `#expect`) | Modern framework, Xcode 15+ |
| AI Providers | Protocol-oriented (`AIProvider: Actor`) | Pluggable, testable, mockable |
| Dependencies | SPM only | No CocoaPods/Carthage |

## Development Setup

### Prerequisites
- Xcode 26 (beta) on macOS
- iOS 26 Simulator or physical device with Apple Intelligence
- (Optional) Ollama running locally: `brew install ollama && ollama serve`

### Running in Xcode

1. Open `Lumen/` as an Xcode project (or create `Lumen.xcodeproj` in the folder)
2. Select target: **iPhone 16 Pro** (iOS 26 simulator)
3. Press **⌘R** to build and run
4. For macOS: select **My Mac** target

### Running Tests

```
⌘U in Xcode → runs LumenTests suite
```

All DataService tests use in-memory SwiftData (`.forTesting()`), so they're fast and isolated.

### Ollama Setup (optional)

```bash
brew install ollama
ollama serve            # Starts server at http://localhost:11434
ollama pull llama3.2    # Download a model
```

Configure the server URL in Lumen → Settings → Ollama Server URL.

## Phased Roadmap

| Phase | Feature | Status |
|-------|---------|--------|
| 0 | Foundation: scaffold, design system, SwiftData | ✅ Complete |
| 1 | Core Chat: Ollama + Foundation Models, streaming UI | 🔲 Next |
| 2 | Enhanced I/O: voice, camera, images, OCR | 🔲 Planned |
| 3 | Intelligence: search, tags, prompt library, comparison | 🔲 Planned |
| 4 | Platform: widgets, Siri, Spotlight, Shortcuts | 🔲 Planned |
| 5 | Advanced: agents, memory, branching | 🔲 Planned |
| 6 | Polish: performance, accessibility, App Store | 🔲 Planned |

## Privacy

- **Zero telemetry** — no analytics, no crash reporting sent to any server
- **On-device or self-hosted** — all AI runs on Apple Intelligence or your own Ollama instance
- **Privacy label: "Data Not Collected"** — the strongest possible App Store stance
- Health data (Phase 5) is read on-device only and never transmitted
