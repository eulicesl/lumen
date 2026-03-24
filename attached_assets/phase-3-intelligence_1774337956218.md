# Phase 3: Intelligence & Organization

> Smart features that make conversations more useful over time.

**Duration:** Week 9-11
**Outcome:** Conversations are searchable, organized, templated, and intelligently enhanced.
**Dependencies:** Phase 1 complete. Phase 2 optional (voice features independent).

---

## Objectives

1. Implement conversation search with full-text and semantic filtering
2. Implement tags and folders for conversation organization
3. Build the prompt template library with variable substitution
4. Implement multi-model comparison (side-by-side)
5. Implement AI-powered conversation summaries and auto-tagging
6. Implement conversation export/import (JSON + Markdown)

---

## User Stories

### US3.1 — Conversation Search
> As a user with hundreds of conversations, I want to find past conversations quickly.

**Acceptance Criteria:**
- Search tab (with `.search` role in TabView) for global search
- Search field in sidebar for quick filtering
- Full-text search across conversation titles and message content
- Results show matching messages with highlighted keywords
- Recent searches remembered
- Filter by: date range, model used, has images, has code

### US3.2 — Tags & Folders
> As a user, I want to organize my conversations into categories.

**Acceptance Criteria:**
- Create, rename, delete tags with color selection
- Assign multiple tags to a conversation (long-press menu)
- Create nested folders for hierarchical organization
- Drag and drop conversations into folders (iPad/Mac)
- Filter sidebar by tag or folder
- "Untagged" smart filter shows uncategorized conversations

### US3.3 — Prompt Template Library
> As a power user, I want reusable prompt templates with variable substitution.

**Acceptance Criteria:**
- Library tab shows prompt templates organized by category
- Categories: General, Writing, Coding, Analysis, Creative, Productivity, Learning, Translation
- Templates support `{{VARIABLE_NAME}}` syntax
- When using a template, a form appears for each variable
- Create, edit, duplicate, delete custom templates
- Built-in sample templates (20+) across all categories
- Import/export template collections (JSON)
- Per-template model temperature setting
- Keyboard shortcut hints for quick access

### US3.4 — Multi-Model Comparison
> As a developer/researcher, I want to compare responses from different models.

**Acceptance Criteria:**
- "Compare" mode accessible from chat header menu
- Select 2-4 models to compare
- Send same prompt to all selected models simultaneously
- Responses display side-by-side (iPad/Mac) or stacked (iPhone)
- Each response shows model name, timing, token count
- Save comparison sessions for future reference
- Copy individual or all responses

### US3.5 — AI-Powered Summaries
> As a user, I want AI to summarize long conversations.

**Acceptance Criteria:**
- "Summarize" action in conversation context menu
- Summary generated using Apple Foundation Models (on-device, free)
- Summary displayed at top of conversation with collapse toggle
- Option to generate summaries for all conversations in bulk
- Scheduled daily/weekly summary digests (background processing)

### US3.6 — Auto-Tagging
> As a user, I want conversations automatically categorized.

**Acceptance Criteria:**
- After each conversation, Foundation Models suggests tags
- User can accept or dismiss suggestions
- Bulk auto-tag all existing conversations
- Tag suggestions based on conversation content analysis

### US3.7 — Export & Import
> As a user, I want to backup and share my conversations.

**Acceptance Criteria:**
- Export formats: JSON (full fidelity), Markdown (human-readable)
- Export single conversation or all conversations
- Import JSON conversations with merge strategy (skip duplicates)
- Share sheet integration for quick export
- File size estimate before export

---

## Technical Implementation

### Search Architecture

```swift
// Services/SearchService.swift

actor SearchService {
    static let shared = SearchService()

    func search(query: String, filters: SearchFilters) async throws -> [SearchResult] {
        // 1. Full-text search in SwiftData using #Predicate
        // 2. Filter by date, model, media presence
        // 3. Rank by relevance (title match > message match > tag match)
        // 4. Return with highlighted snippets
    }
}

struct SearchFilters: Sendable {
    var dateRange: ClosedRange<Date>?
    var modelIDs: Set<String>?
    var hasImages: Bool?
    var hasCode: Bool?
    var tags: Set<UUID>?
    var folder: UUID?
}

struct SearchResult: Identifiable, Sendable {
    let id: UUID
    let conversationID: UUID
    let conversationTitle: String
    let matchingSnippet: String
    let matchType: MatchType  // .title, .message, .tag
    let relevanceScore: Float
    let date: Date
}
```

### Organization SwiftData Models

```swift
@Model
final class ConversationTagSD {
    #Unique([\.id])
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#007AFF"
    var createdAt: Date = Date()

    @Relationship(inverse: \ConversationSD.tags)
    var conversations: [ConversationSD] = []
}

@Model
final class ConversationFolderSD {
    #Unique([\.id])
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0
    var createdAt: Date = Date()

    var parent: ConversationFolderSD?

    @Relationship(deleteRule: .nullify, inverse: \ConversationSD.folder)
    var conversations: [ConversationSD] = []

    @Relationship(deleteRule: .cascade, inverse: \ConversationFolderSD.parent)
    var children: [ConversationFolderSD] = []
}
```

### Prompt Library

```swift
@Model
final class PromptTemplateSD {
    #Unique([\.id])
    var id: UUID = UUID()
    var name: String = ""
    var instruction: String = ""
    var category: String = "general"
    var templateDescription: String?
    var temperature: Float?
    var isBuiltIn: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()

    // Computed: extract {{VARIABLE}} patterns
    var variables: [String] {
        PromptVariableParser.extractVariables(from: instruction)
    }
}

enum PromptVariableParser {
    static func extractVariables(from template: String) -> [String] {
        let pattern = #/\{\{(\w+)\}\}/#
        return template.matches(of: pattern).map { String($0.output.1) }.uniqued()
    }

    static func substitute(template: String, values: [String: String]) -> String {
        var result = template
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
}
```

### Comparison Store

```swift
@Observable
@MainActor
final class ComparisonStore {
    static let shared = ComparisonStore()

    var isComparing: Bool = false
    var selectedModels: [AIModel] = []
    var responses: [AIModel.ID: ComparisonResponse] = [:]

    struct ComparisonResponse {
        var content: String = ""
        var state: ConversationState = .idle
        var tokenCount: Int = 0
        var duration: TimeInterval = 0
    }

    func compare(prompt: String) async {
        for model in selectedModels {
            // Launch parallel streams
            Task {
                await streamResponse(prompt: prompt, model: model)
            }
        }
    }
}
```

### Export/Import Service

```swift
actor ExportImportService {
    static let shared = ExportImportService()

    struct ExportFormat: Codable {
        let version: Int = 1
        let exportDate: Date
        let conversations: [ExportedConversation]
    }

    struct ExportedConversation: Codable {
        let id: UUID
        let title: String
        let createdAt: Date
        let model: String?
        let systemPrompt: String?
        let tags: [String]
        let messages: [ExportedMessage]
    }

    func exportJSON(conversations: [ConversationSD]) async throws -> Data { ... }
    func exportMarkdown(conversation: ConversationSD) async throws -> String { ... }
    func importJSON(data: Data) async throws -> ImportResult { ... }
}
```

---

## Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `Services/SearchService.swift` | Full-text search |
| 2 | `Services/ExportImportService.swift` | JSON/Markdown export-import |
| 3 | `Services/PromptLibraryService.swift` | Template management |
| 4 | `Services/SummaryService.swift` | AI-powered summaries |
| 5 | `Services/AutoTagService.swift` | Foundation Models tagging |
| 6 | `Stores/ComparisonStore.swift` | Side-by-side comparison |
| 7 | `Stores/OrganizationStore.swift` | Tags + folders state |
| 8 | `Stores/LibraryStore.swift` | Prompt templates state |
| 9 | `Data/SwiftData/ConversationTagSD.swift` | Tag model |
| 10 | `Data/SwiftData/ConversationFolderSD.swift` | Folder model |
| 11 | `Data/SwiftData/PromptTemplateSD.swift` | Template model |
| 12 | `Data/SwiftData/ComparisonSessionSD.swift` | Comparison history |
| 13 | `Models/SearchModels.swift` | Search types |
| 14 | `Models/PromptVariableParser.swift` | Template variable parser |
| 15 | `Views/Shared/Search/SearchView.swift` | Search interface |
| 16 | `Views/Shared/Search/SearchResultRow.swift` | Search result item |
| 17 | `Views/Shared/Organization/TagPickerView.swift` | Tag management |
| 18 | `Views/Shared/Organization/FolderTreeView.swift` | Folder navigation |
| 19 | `Views/Shared/Library/LibraryView.swift` | Template library |
| 20 | `Views/Shared/Library/TemplateEditorView.swift` | Create/edit template |
| 21 | `Views/Shared/Library/VariableSubstitutionView.swift` | Variable form |
| 22 | `Views/Shared/Library/TemplateCategoryView.swift` | Category filter |
| 23 | `Views/Shared/Comparison/ComparisonView.swift` | Side-by-side UI |
| 24 | `Views/Shared/Comparison/ComparisonResponseView.swift` | Single model response |
| 25 | `Views/Shared/Export/ExportOptionsView.swift` | Export format picker |
| 26 | `Views/Shared/Sidebar/ConversationContextMenu.swift` | Context menu actions |
| 27 | `Resources/BuiltInTemplates.json` | Default template set |
| 28 | `LumenTests/SearchServiceTests.swift` | Search tests |
| 29 | `LumenTests/PromptVariableParserTests.swift` | Variable parsing tests |
| 30 | `LumenTests/ExportImportTests.swift` | Export/import round-trip tests |

**Total: 30 files**

---

## Acceptance Criteria

### Search
- [ ] Full-text search across titles and message content
- [ ] Results show highlighted matching text
- [ ] Filter by date, model, media presence
- [ ] Recent searches remembered
- [ ] Search accessible from dedicated tab and sidebar

### Organization
- [ ] Create/edit/delete tags with colors
- [ ] Create/edit/delete nested folders
- [ ] Assign tags to conversations
- [ ] Move conversations to folders
- [ ] Filter sidebar by tag or folder
- [ ] Drag-and-drop on iPad/Mac

### Prompt Library
- [ ] 20+ built-in templates across 8 categories
- [ ] `{{VARIABLE}}` extraction and substitution works
- [ ] Create/edit/delete custom templates
- [ ] Import/export template collections
- [ ] Per-template temperature setting
- [ ] Category filtering and search

### Model Comparison
- [ ] Select 2-4 models for comparison
- [ ] Parallel streaming responses
- [ ] Side-by-side display (iPad/Mac) or stacked (iPhone)
- [ ] Token count and timing per model
- [ ] Save/view comparison history

### AI Features
- [ ] Conversation summarization via Foundation Models
- [ ] Auto-tag suggestions after conversations
- [ ] Bulk auto-tag existing conversations

### Export/Import
- [ ] JSON export preserves all data (round-trip lossless)
- [ ] Markdown export is human-readable
- [ ] Bulk export all conversations
- [ ] Import with duplicate detection
- [ ] Share sheet integration

### Testing
- [ ] Search service tests with sample data
- [ ] Variable parser edge case tests
- [ ] Export/import round-trip test
- [ ] At least 15 new passing tests

---

*Phase 3 is where Lumen starts to differentiate. The combination of prompt library + model comparison + auto-tagging is something neither ChatGPT nor Claude offers.*
