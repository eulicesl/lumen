import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore

    @State private var query: String
    @State private var searchTask: Task<Void, Never>?
    @State private var results: [ConversationSearchResult] = []
    @State private var isSearching = false

    init(initialQuery: String = AppLaunchConfiguration.screenshotScene?.searchQuery ?? "") {
        _query = State(initialValue: initialQuery)
    }

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
            .navigationBarInline()
            .searchable(
                text: $query,
                placement: .automatic,
                prompt: "Search conversations and messages…"
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .searchToolbarBehaviorIfAvailable()
            .onChange(of: query) { runSearch() }
            .onAppear {
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && results.isEmpty {
                    runSearch()
                }
            }
        }
    }

    // MARK: - Recent conversations (empty state)

    private var recentConversations: some View {
        List {
            if chatStore.conversations.isEmpty {
                ContentUnavailableView(
                    "No Recent Conversations",
                    systemImage: LumenIcon.chat,
                    description: Text("Your recent conversations appear here when you start chatting.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section("Recent Conversations") {
                    ForEach(chatStore.conversations.prefix(10)) { conversation in
                        conversationRow(conversation)
                    }
                }
            }
        }
        .insetGroupedListStyle()
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
        .insetGroupedListStyle()
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
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No conversations matched \"\(query)\".")
        )
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
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    if !conversation.preview.isEmpty {
                        Text(conversation.preview)
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                    }
                }
                Spacer()
                Text(conversation.updatedAt.relativeFormatted)
                    .font(LumenType.footnote)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(conversation.title)
        .accessibilityValue(conversationRowAccessibilityValue(conversation))
        .accessibilityHint("Opens this conversation")
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
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    Text(result.subtitle)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                }
                Spacer()
                Text(result.conversation.updatedAt.relativeFormatted)
                    .font(LumenType.footnote)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.title)
        .accessibilityValue(searchResultAccessibilityValue(result))
        .accessibilityHint(result.matchedMessageID == nil ? "Opens this conversation" : "Opens this conversation and jumps to the matching message")
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

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }

            let conversations = await MainActor.run { chatStore.conversations }
            let searchResults = await Task.detached(priority: .userInitiated) {
                ConversationSearchEngine.search(
                    trimmedQuery,
                    in: conversations
                )
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run {
                results = searchResults
                isSearching = false
            }
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

    private func conversationRowAccessibilityValue(_ conversation: Conversation) -> String {
        var parts = [String]()
        if conversation.isPinned {
            parts.append("Pinned")
        }

        let preview = conversation.preview.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preview.isEmpty {
            parts.append(preview)
        }
        parts.append("Updated \(conversation.updatedAt.relativeFormatted)")
        return parts.joined(separator: ". ")
    }

    private func searchResultAccessibilityValue(_ result: ConversationSearchResult) -> String {
        var parts = [result.matchedMessageID == nil ? "Conversation match" : "Message match"]
        if result.conversation.isPinned {
            parts.append("Pinned")
        }
        parts.append(result.subtitle)
        parts.append("Updated \(result.conversation.updatedAt.relativeFormatted)")
        return parts.joined(separator: ". ")
    }
}

private extension View {
    @ViewBuilder
    func searchToolbarBehaviorIfAvailable() -> some View {
        // Disabled for now: CI runs Xcode 16 SDK where searchToolbarBehavior is unavailable.
        self
    }

    @ViewBuilder
    func navigationBarInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func insetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self.listStyle(.inset)
        #endif
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
