# Phase 0: Foundation

> Project scaffold, architecture, design system, and build pipeline.

**Duration:** Week 1-2
**Outcome:** Empty app that builds and runs on iOS, iPadOS, and macOS with the design system in place.
**Dependencies:** None (starting point)

---

## Objectives

1. Create a new Xcode project from scratch (not forking Enchanted)
2. Establish the architecture, module structure, and coding conventions
3. Implement the design token system and core UI components
4. Set up SwiftData schema with migrations
5. Set up CI/CD and testing infrastructure
6. Create the AI provider protocol and stub implementations

---

## Deliverables

### D0.1 — Xcode Project Setup

**Create new project: `Lumen.xcodeproj`**

```
Lumen/
├── App/
│   ├── LumenApp.swift              # @main entry point
│   ├── AppDelegate.swift           # iOS lifecycle (BGTasks, deep links)
│   └── ContentView.swift           # Root view with platform branching
├── DesignSystem/
│   ├── LumenTokens.swift           # Spacing, radius, animation tokens
│   ├── LumenColor.swift            # Semantic color definitions
│   ├── LumenIcon.swift             # SF Symbol name constants
│   └── Components/
│       ├── GlassContainer.swift    # Reusable glass effect wrapper
│       ├── LumenButton.swift       # Standard button with states
│       └── LoadingIndicator.swift  # Streaming/typing indicator
├── Models/
│   ├── AIModel.swift               # Domain model for LLM
│   ├── ChatMessage.swift           # Domain model for messages
│   ├── Conversation.swift          # Domain model for conversations
│   ├── ChatToken.swift             # Streaming token type
│   └── Enums/
│       ├── MessageRole.swift       # .user, .assistant, .system
│       ├── ConversationState.swift # .idle, .generating, .error
│       └── AIProviderType.swift    # .ollama, .foundationModels
├── Data/
│   ├── SwiftData/
│   │   ├── ConversationSD.swift    # @Model conversation
│   │   ├── MessageSD.swift         # @Model message
│   │   ├── AIModelSD.swift         # @Model for saved models
│   │   └── Schema.swift            # VersionedSchema + migration plan
│   └── DataService.swift           # Actor-based SwiftData access
├── Services/
│   ├── Providers/
│   │   ├── AIProvider.swift        # Protocol definition
│   │   ├── OllamaProvider.swift    # Ollama API client (stub)
│   │   └── FoundationModelsProvider.swift # Apple FM (stub)
│   └── AIService.swift             # Provider resolver + routing
├── Stores/
│   ├── AppStore.swift              # Global app state
│   ├── ChatStore.swift             # Chat state (stub)
│   └── ModelStore.swift            # Model management (stub)
├── Views/
│   ├── Shared/                     # Cross-platform views
│   ├── iOS/                        # iPhone/iPad specific
│   └── macOS/                      # macOS specific
├── Extensions/
│   └── (Swift extensions as needed)
└── Resources/
    ├── Assets.xcassets/            # App icon, colors
    └── Info.plist
```

**Xcode Targets:**
- `Lumen` — Main app (iOS, iPadOS, macOS)
- `LumenTests` — Unit tests
- `LumenUITests` — UI tests
- `LumenWidgets` — Widget extension (placeholder, implemented Phase 4)

**Build Configuration:**
- Deployment target: iOS 26.0, macOS 26.0
- Swift 6 strict concurrency (`-strict-concurrency=complete`)
- `SWIFT_STRICT_CONCURRENCY = complete` build setting
- Enable all recommended warnings

### D0.2 — AI Provider Protocol

```swift
// Services/Providers/AIProvider.swift

import Foundation

/// Represents a single token or chunk from a streaming AI response.
struct ChatToken: Sendable {
    let text: String
    let isComplete: Bool
    let tokenCount: Int?
}

/// Options for a chat completion request.
struct ChatOptions: Sendable {
    var temperature: Float = 0.7
    var systemPrompt: String?
    var maxTokens: Int?
    var stream: Bool = true
}

/// Protocol that all AI providers must conform to.
protocol AIProvider: Actor {
    /// Unique identifier for this provider.
    var id: String { get }

    /// Human-readable name.
    var displayName: String { get }

    /// Check if this provider is currently available.
    func checkAvailability() async -> Bool

    /// List available models from this provider.
    func listModels() async throws -> [AIModel]

    /// Stream a chat completion.
    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error>
}
```

### D0.3 — SwiftData Schema

```swift
// Data/SwiftData/ConversationSD.swift
import SwiftData

@Model
final class ConversationSD {
    #Unique([\.id])

    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPinned: Bool = false
    var systemPrompt: String?

    @Relationship(deleteRule: .cascade, inverse: \MessageSD.conversation)
    var messages: [MessageSD] = []

    @Relationship(deleteRule: .nullify)
    var model: AIModelSD?
}

// Data/SwiftData/MessageSD.swift
@Model
final class MessageSD {
    #Unique([\.id])

    var id: UUID = UUID()
    var content: String = ""
    var role: String = "user"    // "user", "assistant", "system"
    var createdAt: Date = Date()
    var isComplete: Bool = true
    var isError: Bool = false
    var tokenCount: Int?

    @Attribute(.externalStorage)
    var imageData: Data?

    var conversation: ConversationSD?
}

// Data/SwiftData/AIModelSD.swift
@Model
final class AIModelSD {
    #Unique([\.id])

    var id: UUID = UUID()
    var name: String = ""
    var provider: String = "ollama"
    var supportsImages: Bool = false
    var supportsStreaming: Bool = true
    var contextLength: Int?
}
```

### D0.4 — DataService Actor

```swift
// Data/DataService.swift

import SwiftData
import Foundation

/// Thread-safe SwiftData access via Actor isolation.
actor DataService {
    static let shared = DataService()

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private init() {
        let schema = Schema([
            ConversationSD.self,
            MessageSD.self,
            AIModelSD.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        self.modelContainer = try! ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    // CRUD operations defined here...
}
```

### D0.5 — Design System Components

Implement from `design.md`:
- `LumenTokens.swift` — All spacing, radius, animation, icon constants
- `LumenColor.swift` — Semantic color enum
- `GlassContainer.swift` — Reusable `.glassEffect()` wrapper with fallback
- `LumenButton.swift` — Primary/secondary/destructive button styles
- `LoadingIndicator.swift` — Typing dots + streaming pulse

### D0.6 — App Shell

**iOS/iPadOS:**
```swift
// Views/iOS/MainTabView.swift
TabView {
    Tab("Chat", systemImage: LumenIcon.chat) {
        Text("Chat — Phase 1")
    }
    Tab("Voice", systemImage: LumenIcon.voice) {
        Text("Voice — Phase 2")
    }
    Tab("Library", systemImage: LumenIcon.library) {
        Text("Library — Phase 3")
    }
    Tab(role: .search) {
        Text("Search — Phase 3")
    }
    Tab("Settings", systemImage: LumenIcon.settings) {
        Text("Settings — Phase 1")
    }
}
```

**macOS:**
```swift
// Views/macOS/MacContentView.swift
NavigationSplitView {
    Text("Sidebar — Phase 1")
} detail: {
    Text("Chat — Phase 1")
}
.toolbar { ... }
```

### D0.7 — Testing Infrastructure

```swift
// LumenTests/DataServiceTests.swift
import Testing
@testable import Lumen

@Suite("DataService")
struct DataServiceTests {
    @Test("Create and fetch conversation")
    func createConversation() async throws {
        let service = DataService.forTesting()  // In-memory container
        let id = try await service.createConversation(title: "Test")
        let conversation = try await service.fetchConversation(id: id)
        #expect(conversation?.title == "Test")
    }
}
```

- Use Swift Testing framework (`import Testing`, `@Test`, `@Suite`, `#expect`)
- DataService provides `.forTesting()` factory with in-memory store
- Provider protocol enables mock providers for testing

---

## Acceptance Criteria

- [ ] `Lumen.xcodeproj` opens in Xcode 26 without errors
- [ ] App builds and runs on iOS 26 Simulator
- [ ] App builds and runs on iPadOS 26 Simulator
- [ ] App builds and runs on macOS 26
- [ ] Tab bar shows on iPhone with 5 placeholder tabs
- [ ] NavigationSplitView shows on iPad/Mac with placeholder content
- [ ] Liquid Glass tab bar minimizes on scroll (even with placeholder content)
- [ ] All design tokens compile and are accessible
- [ ] SwiftData schema creates database on first launch
- [ ] DataService actor creates/reads/deletes conversations in tests
- [ ] AIProvider protocol compiles with stub implementations
- [ ] `swift build` succeeds with strict concurrency (zero warnings)
- [ ] At least 5 unit tests pass (DataService CRUD + provider mock)
- [ ] App icon renders on home screen (simple placeholder)

---

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Swift version | 6 (strict concurrency) | Future-proof, catches threading bugs at compile time |
| Persistence | SwiftData | Native, SwiftUI-integrated, iCloud-ready |
| State management | @Observable | Modern, no Combine boilerplate |
| Testing framework | Swift Testing | Modern, expressive, built into Xcode 26 |
| Dependency management | SPM only | No CocoaPods/Carthage |
| Min deployment | iOS 26.0 | Clean break, full API access |
| Architecture | MVVM with Stores + Actor Services | Clean separation, testable, thread-safe |

---

## Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `App/LumenApp.swift` | App entry point |
| 2 | `App/ContentView.swift` | Root view router |
| 3 | `DesignSystem/LumenTokens.swift` | Design tokens |
| 4 | `DesignSystem/LumenColor.swift` | Semantic colors |
| 5 | `DesignSystem/LumenIcon.swift` | SF Symbol names |
| 6 | `DesignSystem/Components/GlassContainer.swift` | Glass wrapper |
| 7 | `DesignSystem/Components/LumenButton.swift` | Button styles |
| 8 | `DesignSystem/Components/LoadingIndicator.swift` | Loading states |
| 9 | `Models/AIModel.swift` | LLM model type |
| 10 | `Models/ChatMessage.swift` | Message type |
| 11 | `Models/Conversation.swift` | Conversation type |
| 12 | `Models/ChatToken.swift` | Stream token |
| 13 | `Models/Enums/MessageRole.swift` | Role enum |
| 14 | `Models/Enums/ConversationState.swift` | State enum |
| 15 | `Models/Enums/AIProviderType.swift` | Provider enum |
| 16 | `Data/SwiftData/ConversationSD.swift` | DB conversation |
| 17 | `Data/SwiftData/MessageSD.swift` | DB message |
| 18 | `Data/SwiftData/AIModelSD.swift` | DB model |
| 19 | `Data/SwiftData/Schema.swift` | Versioned schema |
| 20 | `Data/DataService.swift` | Actor DB service |
| 21 | `Services/Providers/AIProvider.swift` | Provider protocol |
| 22 | `Services/Providers/OllamaProvider.swift` | Ollama stub |
| 23 | `Services/Providers/FoundationModelsProvider.swift` | FM stub |
| 24 | `Services/AIService.swift` | Provider router |
| 25 | `Stores/AppStore.swift` | Global state |
| 26 | `Stores/ChatStore.swift` | Chat state stub |
| 27 | `Stores/ModelStore.swift` | Model state stub |
| 28 | `Views/iOS/MainTabView.swift` | iOS tab navigation |
| 29 | `Views/macOS/MacContentView.swift` | macOS split view |
| 30 | `LumenTests/DataServiceTests.swift` | Data layer tests |
| 31 | `LumenTests/AIProviderMock.swift` | Mock provider |

**Total: 31 files**

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Swift 6 strict concurrency friction | Start strict from day one; fix issues immediately rather than accumulating `@unchecked Sendable` |
| SwiftData bugs in iOS 26 | Keep schema simple; test thoroughly; have fallback to UserDefaults for settings |
| macOS target differences | Use `#if os()` sparingly; share 90% of code via Shared/ views |

---

*Phase 0 is complete when a brand-new app builds, runs, and tests pass on all 3 platforms with the full architecture skeleton in place.*
