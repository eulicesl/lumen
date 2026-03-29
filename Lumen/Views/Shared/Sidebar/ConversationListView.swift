import SwiftUI

struct ConversationListView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var searchText = ""
    @State private var renamingConversation: Conversation?
    @State private var renameText = ""
    @State private var promptConversation: Conversation?

    var body: some View {
        List(selection: Binding(
            get: { chatStore.selectedConversation?.id },
            set: { id in
                if let id, let conv = chatStore.conversations.first(where: { $0.id == id }) {
                    Task { await chatStore.selectConversation(conv) }
                }
            }
        )) {
            if filtered.isEmpty {
                emptyState
            } else {
                ForEach(groupedKeys, id: \.self) { key in
                    Section(key.rawValue) {
                        ForEach(grouped[key] ?? []) { conversation in
                            ConversationRowView(
                                conversation: conversation,
                                isSelected: chatStore.selectedConversation?.id == conversation.id
                            )
                            .tag(conversation.id)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    HapticEngine.impact(.light)
                                    Task { await chatStore.togglePin(conversation) }
                                } label: {
                                    Label(
                                        conversation.isPinned ? "Unpin" : "Pin",
                                        systemImage: conversation.isPinned ? LumenIcon.pinSlash : LumenIcon.pin
                                    )
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticEngine.notification(.warning)
                                    Task { await chatStore.deleteConversation(conversation) }
                                } label: {
                                    Label("Delete", systemImage: LumenIcon.trash)
                                }
                                Button {
                                    renamingConversation = conversation
                                    renameText = conversation.title
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    renamingConversation = conversation
                                    renameText = conversation.title
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    Task { await chatStore.togglePin(conversation) }
                                } label: {
                                    Label(
                                        conversation.isPinned ? "Unpin" : "Pin",
                                        systemImage: conversation.isPinned ? LumenIcon.pinSlash : LumenIcon.pin
                                    )
                                }
                                Button {
                                    promptConversation = conversation
                                } label: {
                                    Label(
                                        conversation.hasSystemPrompt ? "Edit System Prompt" : "Set System Prompt",
                                        systemImage: "brain.head.profile"
                                    )
                                }
                                Menu("Export") {
                                    ForEach(ConversationExportFormat.allCases) { format in
                                        if let export = chatStore.exportFile(for: conversation, format: format) {
                                            ShareLink(
                                                item: export,
                                                preview: SharePreview(export.filename)
                                            ) {
                                                Label(format.title, systemImage: format.iconName)
                                            }
                                        }
                                    }
                                }
                                Divider()
                                Button(role: .destructive) {
                                    Task { await chatStore.deleteConversation(conversation) }
                                } label: {
                                    Label("Delete", systemImage: LumenIcon.trash)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "Search conversations")
        .navigationTitle("Lumen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticEngine.impact(.medium)
                    Task { await chatStore.createNewConversation() }
                } label: {
                    Image(systemName: LumenIcon.newChat)
                }
                .accessibilityLabel("New Conversation")
            }
        }
        .sheet(item: $promptConversation) { conversation in
            SystemPromptSheet(conversation: conversation)
                .environment(chatStore)
        }
        .alert("Rename", isPresented: Binding(
            get: { renamingConversation != nil },
            set: { if !$0 { renamingConversation = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Rename") {
                if let conv = renamingConversation, !renameText.isEmpty {
                    Task { await chatStore.renameConversation(conv, to: renameText) }
                }
                renamingConversation = nil
            }
            Button("Cancel", role: .cancel) {
                renamingConversation = nil
            }
        }
        .task {
            await chatStore.loadConversations()
            if chatStore.conversations.isEmpty {
                await chatStore.createNewConversation()
            }
        }
    }

    // MARK: - Filtering + grouping

    private var filtered: [Conversation] {
        if searchText.isEmpty { return chatStore.conversations }
        let q = searchText.lowercased()
        return chatStore.conversations.filter {
            $0.title.lowercased().contains(q) || $0.preview.lowercased().contains(q)
        }
    }

    private var grouped: [Date.ConversationGroup: [Conversation]] {
        let pinned = filtered.filter(\.isPinned)
        let unpinned = filtered.filter { !$0.isPinned }
        var result: [Date.ConversationGroup: [Conversation]] = [:]
        if !pinned.isEmpty {
            result[.pinned] = pinned
        }
        for conv in unpinned {
            let key = conv.updatedAt.conversationGroup
            result[key, default: []].append(conv)
        }
        return result
    }

    private var groupedKeys: [Date.ConversationGroup] {
        Date.ConversationGroup.allCases.filter { grouped[$0] != nil }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            searchText.isEmpty ? "No Conversations" : "No Results",
            systemImage: searchText.isEmpty ? LumenIcon.chat : "magnifyingglass",
            description: Text(searchText.isEmpty
                ? "Tap + to start a new conversation."
                : "No conversations match \"\(searchText)\".")
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NavigationStack {
        ConversationListView()
            .environment(ChatStore.shared)
            .environment(AppStore.shared)
    }
}
