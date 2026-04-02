import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(MemoryStore.self) private var memoryStore

    @SceneStorage("scene.selectedConversationID") private var restoredConversationID: String?
    @State private var showingConversationList = false
    @State private var activePanel: iPhoneQuickPanel?
    @State private var appliedLaunchPanel = false
    @State private var showingModelPicker = false
    @State private var showingComparison = false
    @State private var showingSystemPrompt = false

    var body: some View {
        @Bindable var bindableStore = appStore

        NavigationStack {
            ChatView(showsConversationTools: false)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            showingConversationList = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                        .accessibilityLabel("Open history")
                        .accessibilityHint("Shows your conversation list")

                        ModelPickerChip {
                            showingModelPicker = true
                        }
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            Task { await chatStore.createNewConversation() }
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("New chat")
                        .accessibilityHint("Starts a new conversation")

                        Menu {
                            Button {
                                activePanel = .voice
                            } label: {
                                Label("Voice", systemImage: LumenIcon.voice)
                            }

                            Button {
                                activePanel = .library
                            } label: {
                                Label("Library", systemImage: LumenIcon.library)
                            }

                            Button {
                                activePanel = .search
                            } label: {
                                Label("Search", systemImage: LumenIcon.search)
                            }

                            Button {
                                showingComparison = true
                            } label: {
                                Label("Compare Models", systemImage: "arrow.left.arrow.right.circle")
                            }

                            if let conv = chatStore.selectedConversation {
                                Button {
                                    showingSystemPrompt = true
                                } label: {
                                    Label(
                                        conv.hasSystemPrompt ? "Edit System Prompt" : "Set System Prompt",
                                        systemImage: "brain.head.profile"
                                    )
                                }
                            }

                            if !chatStore.exportText.isEmpty {
                                ShareLink(item: chatStore.exportText) {
                                    Label("Share Conversation", systemImage: LumenIcon.share)
                                }
                            }

                            Divider()

                            Button {
                                appStore.showingSettings = true
                            } label: {
                                Label("Settings", systemImage: LumenIcon.settings)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open tools menu")
                        .accessibilityHint("Opens voice, library, search, and settings options")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    ChatComposerChrome()
                }
        }
        .sheet(isPresented: $showingConversationList) {
            ConversationPickerView()
                .environment(appStore)
                .environment(chatStore)
        }
        .sheet(item: $activePanel) { panel in
            NavigationStack {
                switch panel {
                case .voice:
                    VoiceInputView()
                        .navigationTitle("Voice")
                case .library:
                    PromptLibraryView()
                        .navigationTitle("Library")
                case .search:
                    SearchView()
                        .navigationTitle("Search")
                }
            }
            .environment(appStore)
            .environment(chatStore)
            .environment(modelStore)
            .environment(libraryStore)
        }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView()
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
        }
        .sheet(isPresented: $showingComparison) {
            ModelComparisonView()
                .environment(chatStore)
                .environment(modelStore)
        }
        .sheet(isPresented: $showingSystemPrompt) {
            if let conv = chatStore.selectedConversation {
                SystemPromptSheet(conversation: conv)
                    .environment(chatStore)
            }
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsView()
            .environment(appStore)
            .environment(chatStore)
            .environment(modelStore)
            .environment(libraryStore)
            .environment(memoryStore)
        }
        .task {
            await restoreSceneSelectionIfNeeded()
            await applyLaunchPresentationIfNeeded()
        }
        .onChange(of: chatStore.conversations.count) {
            Task { await restoreSceneSelectionIfNeeded() }
        }
        .onChange(of: chatStore.selectedConversation?.id.uuidString) {
            restoredConversationID = chatStore.selectedConversation?.id.uuidString
        }
    }
}

private enum iPhoneQuickPanel: String, Identifiable {
    case voice, library, search

    var id: String { rawValue }
}

private extension MainTabView {
    func restoreSceneSelectionIfNeeded() async {
        let restoredID = restoredConversationID.flatMap(UUID.init(uuidString:))
        await chatStore.restoreSelectedConversation(id: restoredID)
    }

    func applyLaunchPresentationIfNeeded() async {
        guard !appliedLaunchPanel else { return }
        appliedLaunchPanel = true

        guard AppLaunchConfiguration.screenshotScene?.opensSearchPanel == true else { return }
        for _ in 0..<20 where chatStore.conversations.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
        }
        activePanel = .search
    }
}

extension NavigationSplitViewVisibility {
    init(sceneStorageValue: String, fallback: NavigationSplitViewVisibility) {
        switch sceneStorageValue {
        case "all":
            self = .all
        case "detailOnly":
            self = .detailOnly
        case "automatic":
            self = .automatic
        default:
            self = fallback
        }
    }

    var sceneStorageValue: String {
        switch self {
        case .all:
            return "all"
        case .detailOnly:
            return "detailOnly"
        default:
            return "automatic"
        }
    }
}

private struct ModelPickerChip: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ProviderMark(
                    provider: currentProviderType,
                    size: 15,
                    showsVariantBadge: currentProviderType != .foundationModels
                )

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .fixedSize(horizontal: true, vertical: false)
            .liquidCapsuleChrome()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current model")
        .accessibilityValue(currentModelAccessibilityValue)
        .accessibilityHint("Double-tap to choose a different model")
        .task {
            if modelStore.availableModels.isEmpty {
                await modelStore.loadModels()
            }
        }
    }

    private var currentModelAccessibilityValue: String {
        guard let model = chatStore.currentModel else { return "No model selected" }
        return "\(providerTitle(for: model)). \(model.displayName)"
    }

    private var currentProviderType: AIProviderType {
        chatStore.currentModel?.providerType ?? .foundationModels
    }

    private func providerTitle(for model: AIModel) -> String {
        model.providerType.displayName
    }
}

private extension View {
    @ViewBuilder
    func liquidCapsuleChrome() -> some View {
        if #available(iOS 26.0, *) {
            self.glassCard(radius: LumenRadius.full, interactive: true)
        } else {
            self.background(.thinMaterial, in: Capsule())
        }
    }
}

private struct ChatComposerChrome: View {
    var body: some View {
        InputBarView()
    }
}

private struct ConversationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ConversationListView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct PlaceholderView: View {

    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        NavigationStack {
            VStack(spacing: LumenSpacing.lg) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(LumenType.largeTitle)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(LumenType.messageBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, LumenLayout.iPhoneEdgePadding)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview("Main Tab") {
    MainTabView()
        .environment(AppStore.shared)
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
        .environment(LibraryStore.shared)
}

#Preview("Placeholder") {
    PlaceholderView(
        title: "Prompt Library",
        subtitle: "Quick actions and reusable prompts appear here.",
        icon: LumenIcon.library
    )
}
