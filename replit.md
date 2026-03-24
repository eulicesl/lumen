# Lumen AI

A privacy-first, iOS 26 native AI assistant with Liquid Glass design, multi-provider support, and deep Apple ecosystem integration.

## Overview

Lumen is a native Swift/SwiftUI app targeting iOS 26, iPadOS 26, and macOS 26. It runs AI inference entirely on the user's own infrastructure — either Apple Intelligence (on-device) or Ollama (self-hosted). Zero cloud dependency, zero telemetry.

**Note:** This is a native Xcode project. All Swift source files live in `Lumen/`. To build and run, open the project in **Xcode 26** on macOS.

## Project Structure

```
Lumen/
├── App/
│   ├── LumenApp.swift             # @main, injects AppStore/ChatStore/ModelStore environments
│   ├── AppDelegate.swift          # BGTasks, deep links (#if os(iOS))
│   └── ContentView.swift          # Platform branch: iPhone→TabView, iPad→SplitView, Mac→SplitView
├── DesignSystem/
│   ├── LumenTokens.swift          # Spacing, radius, animation, typography tokens
│   ├── LumenColor.swift           # Semantic system colors
│   ├── LumenIcon.swift            # SF Symbol name constants
│   └── Components/
│       ├── GlassContainer.swift   # .glassEffect() wrapper with fallback
│       ├── LumenButton.swift      # Primary/secondary/destructive/ghost/icon styles
│       └── LoadingIndicator.swift # TypingIndicator + StreamingPulse
├── Models/                        # Domain value types (Sendable, Codable)
│   ├── AIModel.swift              # AI model descriptor + shortName computed property
│   ├── ChatMessage.swift          # Message with role, content, [Data]? images
│   ├── Conversation.swift         # Conversation with messages + metadata
│   ├── ChatToken.swift            # Streaming token + ChatOptions
│   └── Enums/
│       ├── MessageRole.swift
│       ├── ConversationState.swift
│       └── AIProviderType.swift
├── Data/
│   ├── SwiftData/
│   │   ├── ConversationSD.swift   # @Model with cascade messages
│   │   ├── MessageSD.swift        # @Model with [Data]? imageData external storage
│   │   ├── AIModelSD.swift        # @Model for persisted model configs
│   │   └── Schema.swift           # VersionedSchema + migration plan
│   └── DataService.swift          # nonisolated modelContainer, actor-isolated CRUD
├── Services/
│   ├── Providers/
│   │   ├── AIProvider.swift       # Protocol: AIProvider: Actor
│   │   ├── OllamaProvider.swift   # Full Ollama NDJSON streaming
│   │   └── FoundationModelsProvider.swift  # Apple Foundation Models (#if canImport)
│   ├── AIService.swift            # Provider router + availability check
│   ├── VoiceService.swift         # SFSpeechRecognizer + AVAudioEngine, AsyncStream<VoiceTranscript> (#if os(iOS))
│   └── ImageService.swift         # UIImage resize, Vision OCR, thumbnail generation
├── Stores/
│   ├── AppStore.swift             # selectedTab, colorSchemePreference, ollamaServerURL
│   ├── ChatStore.swift            # messages, streaming Task { @MainActor in }
│   └── ModelStore.swift           # availableModels, loads on startup, syncs to ChatStore
├── Views/
│   ├── Shared/
│   │   ├── Chat/
│   │   │   ├── ChatView.swift            # ScrollView + LazyVStack, auto-scroll, empty states
│   │   │   ├── MessageBubbleView.swift   # User/assistant/streaming/error bubbles + think-blocks + image grid
│   │   │   ├── InputBarView.swift        # Multiline TextField, model chip, photo/camera/voice, send/stop
│   │   │   ├── ImageAttachmentRow.swift  # Horizontal thumbnail strip with remove/OCR actions
│   │   │   └── MessageImageGrid.swift    # 2-col grid with fullscreen viewer
│   │   ├── Voice/
│   │   │   ├── VoiceInputView.swift      # Full-screen voice tab: transcript history, send to chat
│   │   │   └── VoiceWaveformView.swift   # Animated bar waveform + circular pulse indicator
│   │   ├── Sidebar/
│   │   │   ├── ConversationListView.swift # Grouped list, search, swipe, context menu
│   │   │   └── ConversationRowView.swift  # Title + preview + timestamp + pin indicator
│   │   ├── Models/
│   │   │   └── ModelPickerView.swift     # Ollama + Apple Intelligence sections, availability
│   │   │   ├── Settings/
│   │   │   └── SettingsView.swift        # Ollama URL, Apple Intelligence status, appearance
│   │   ├── Search/
│   │   │   └── SearchView.swift          # Live fuzzy search across conversations; tap → select + switch to chat
│   │   ├── Library/
│   │   │   └── PromptLibraryView.swift   # 17 built-in prompts by category, favorites, custom prompts, detail sheet
│   │   └── Compare/
│   │       └── ModelComparisonView.swift # Side-by-side (iPad) / stacked (iPhone) model comparison with TTFT
│   ├── iOS/
│   │   ├── MainTabView.swift      # 5-tab: Chat (SplitView), Voice, Library, Search, Settings
│   │   └── iPadContentView.swift  # NavigationSplitView for regular width (iPad)
│   └── macOS/
│       └── MacContentView.swift   # NavigationSplitView + toolbar + keyboard shortcuts
├── Extensions/
│   ├── Date+Grouping.swift        # Today/Yesterday/7 days/30 days conversation grouping
│   └── String+Markdown.swift      # Markdown helpers, think-block parsing, AttributedString
└── Resources/
    └── Info.plist

LumenTests/
├── DataServiceTests.swift
└── AIProviderMock.swift
```

## Architecture

```
UI Layer (SwiftUI Views)
  ChatView · MessageBubbleView · InputBarView
  ConversationListView · ModelPickerView · SettingsView
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

## Key Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Language | Swift 6, `-strict-concurrency=complete` | Catches threading bugs at compile time |
| UI | SwiftUI (iOS 26 APIs) | Native, Liquid Glass, declarative |
| Persistence | SwiftData | Native, iCloud-ready, SwiftUI-integrated |
| State | `@Observable` + `@Bindable` | Modern, no ObservableObject overhead |
| Services | `actor` isolation | Thread-safe, no DispatchQueue |
| Chat streaming | `Task { @MainActor in }` | Explicit MainActor for all UI state mutations |
| DataService.modelContainer | `nonisolated` | Safely accessible from LumenApp.body |
| Testing | Swift Testing (`@Test`, `@Suite`, `#expect`) | Modern framework |
| AI Providers | Protocol-oriented (`AIProvider: Actor`) | Pluggable, testable, mockable |

## Development Setup

### Prerequisites
- Xcode 26 (beta) on macOS 26
- iOS 26 Simulator or physical device
- (Optional) Ollama running locally: `brew install ollama && ollama serve`

### Create the Xcode Project

1. Open Xcode 26
2. Create a new Swift/SwiftUI multiplatform app
3. Move/overwrite source files from `Lumen/` into the Xcode project
4. Add `LumenTests/` as a test target
5. Set minimum deployment: iOS 26, macOS 26
6. Enable `-strict-concurrency=complete` in Swift compiler flags

### Ollama Setup

```bash
brew install ollama
ollama serve                  # Starts server at http://localhost:11434
ollama pull llama3.2          # Pull a model
ollama pull deepseek-r1:8b    # Pull a reasoning model (supports <think> blocks)
```

Configure the server URL in Lumen → Settings → Ollama Server URL.

## Phased Roadmap

| Phase | Feature | Status |
|-------|---------|--------|
| 0 | Foundation: scaffold, design system, SwiftData | ✅ Complete |
| 1 | Core Chat: streaming UI, sidebar, model picker, settings | ✅ Complete |
| 2 | Enhanced I/O: voice, camera, images, OCR | ✅ Complete |
| 3 | Intelligence: search, prompt library, model comparison | ✅ Complete |
| 4 | Platform: widgets, Siri, Spotlight, Shortcuts | 🔲 Planned |
| 5 | Advanced: agents, memory, branching | 🔲 Planned |
| 6 | Polish: performance, accessibility, App Store | 🔲 Planned |

## Privacy

- **Zero telemetry** — no analytics, no crash reporting sent to any server
- **On-device or self-hosted** — all AI runs on Apple Intelligence or your own Ollama instance
- **Privacy label: "Data Not Collected"** — the strongest possible App Store stance
