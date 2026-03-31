import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore

    @State private var query = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var results: [ConversationSearchResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            Group {
                if query.isEmpty {
                    recentConversations
                } else if isSearching {
                    searchingIndicator
                } else if results.isEmpty {
                    emptyResults
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search conversations and messages…"
            )
            .onChange(of: query) { runSearch() }
        }
    }

    // MARK: - Recent conversations (empty state)

    private var recentConversations: some View {
        List {
            if !chatStore.conversations.isEmpty {
                Section("Recent Conversations") {
                    ForEach(chatStore.conversations.prefix(10)) { conversation in
                        conversationRow(conversation)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Results list

    private var resultsList: some View {
        List {
            let grouped = Dictionary(grouping: results, by: \.section)
            ForEach(SearchSection.allCases, id: \.self) { section in
                if let items = grouped[section], !items.isEmpty {
                    Section(section.label) {
                        ForEach(items) { result in
                            searchResultRow(result)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - States

    private var searchingIndicator: some View {
        VStack(spacing: LumenSpacing.md) {
            Spacer()
            ProgressView()
            Text("Searching…")
                .font(LumenType.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var emptyResults: some View {
        VStack(spacing: LumenSpacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No results for \"\(query)\"")
                .font(LumenType.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Row views

    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        Button {
            selectConversation(conversation)
        } label: {
            HStack(spacing: LumenSpacing.md) {
                Image(systemName: conversation.isPinned ? LumenIcon.pin : LumenIcon.chat)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                    Text(conversation.title)
                        .font(LumenType.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !conversation.preview.isEmpty {
                        Text(conversation.preview)
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text(conversation.updatedAt.relativeFormatted)
                    .font(LumenType.footnote)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func searchResultRow(_ result: ConversationSearchResult) -> some View {
        Button {
            openSearchResult(result)
        } label: {
            HStack(spacing: LumenSpacing.md) {
                Image(systemName: result.symbolName)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                    Text(result.title)
                        .font(LumenType.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(result.subtitle)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(result.conversation.updatedAt.relativeFormatted)
                    .font(LumenType.footnote)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search logic

    private func runSearch() {
        searchTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }

            results = ConversationSearchEngine.search(
                trimmedQuery,
                in: chatStore.conversations
            )
            isSearching = false
        }
    }

    private func selectConversation(_ conversation: Conversation) {
        Task {
            await chatStore.selectConversation(conversation)
            appStore.selectedTab = .chat
            dismiss()
        }
    }

    private func openSearchResult(_ result: ConversationSearchResult) {
        Task {
            await chatStore.selectConversation(
                result.conversation,
                focusingOn: result.matchedMessageID
            )
            appStore.selectedTab = .chat
            dismiss()
        }
    }
}

// MARK: - Supporting types

struct ConversationSearchResult: Identifiable {
    let id: UUID
    let section: SearchSection
    let title: String
    let subtitle: String
    let conversation: Conversation
    let matchedMessageID: UUID?

    var symbolName: String {
        matchedMessageID == nil ? LumenIcon.chat : "text.bubble"
    }
}

enum SearchSection: CaseIterable {
    case conversations, messages

    var label: String {
        switch self {
        case .conversations: return "Conversations"
        case .messages:      return "Messages"
        }
    }
}

enum ConversationSearchEngine {
    static let maxMessageMatchesPerConversation = 5

    static func search(
        _ rawQuery: String,
        in conversations: [Conversation]
    ) -> [ConversationSearchResult] {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let normalizedQuery = query.lowercased()
        var results: [ConversationSearchResult] = []

        for conversation in conversations {
            if conversation.title.lowercased().contains(normalizedQuery) {
                results.append(
                    ConversationSearchResult(
                        id: conversation.id,
                        section: .conversations,
                        title: conversation.title,
                        subtitle: conversation.preview.isEmpty ? "No messages" : conversation.preview,
                        conversation: conversation,
                        matchedMessageID: nil
                    )
                )
            }

            let messageMatches = conversation.messages
                .filter { !$0.isSystem && !$0.content.isEmpty }
                .filter { $0.content.lowercased().contains(normalizedQuery) }
                .prefix(maxMessageMatchesPerConversation)

            for message in messageMatches {
                results.append(
                    ConversationSearchResult(
                        id: message.id,
                        section: .messages,
                        title: "\(conversation.title) · \(message.role.displayName)",
                        subtitle: highlightedExcerpt(
                            from: message.content,
                            around: normalizedQuery
                        ),
                        conversation: conversation,
                        matchedMessageID: message.id
                    )
                )
            }
        }

        return results
    }

    static func highlightedExcerpt(
        from text: String,
        around normalizedQuery: String
    ) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: normalizedQuery) else {
            return String(text.prefix(80))
        }

        let start = lower.index(
            range.lowerBound,
            offsetBy: -20,
            limitedBy: lower.startIndex
        ) ?? lower.startIndex
        let end = lower.index(
            range.upperBound,
            offsetBy: 60,
            limitedBy: lower.endIndex
        ) ?? lower.endIndex
        let slice = String(text[start..<end])

        return (start > lower.startIndex ? "…" : "")
            + slice
            + (end < lower.endIndex ? "…" : "")
    }
}

// MARK: - Date helper

private extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    SearchView()
        .environment(ChatStore.shared)
        .environment(AppStore.shared)
}
