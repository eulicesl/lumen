import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(MemoryStore.self) private var memoryStore

    @Namespace private var toolbarTransitionNamespace
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
                    ToolbarItem(placement: .topBarLeading) {
                        historyButton
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        ModelPickerChip {
                            showingModelPicker = true
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        toolsMenu
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
                .lightweightSheetPresentation()
                .toolbarSheetTransition(
                    source: .history,
                    namespace: toolbarTransitionNamespace
                )
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
            .lightweightSheetPresentation()
            .toolbarSheetTransition(
                source: .tools,
                namespace: toolbarTransitionNamespace
            )
        }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView()
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
                .lightweightSheetPresentation()
                .toolbarSheetTransition(
                    source: .modelPicker,
                    namespace: toolbarTransitionNamespace
                )
        }
        .sheet(isPresented: $showingComparison) {
            ModelComparisonView()
                .environment(chatStore)
                .environment(modelStore)
                .toolbarSheetTransition(
                    source: .tools,
                    namespace: toolbarTransitionNamespace
                )
        }
        .sheet(isPresented: $showingSystemPrompt) {
            if let conv = chatStore.selectedConversation {
                SystemPromptSheet(conversation: conv)
                    .environment(chatStore)
                    .toolbarSheetTransition(
                        source: .tools,
                        namespace: toolbarTransitionNamespace
                    )
            }
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsView()
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
                .environment(libraryStore)
                .environment(memoryStore)
                .toolbarSheetTransition(
                    source: .tools,
                    namespace: toolbarTransitionNamespace
                )
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

private enum ToolbarSheetSource: String {
    case history
    case modelPicker
    case tools

    var id: String { rawValue }
}

private extension MainTabView {
    var historyButton: some View {
        Button {
            showingConversationList = true
        } label: {
            Image(systemName: "line.3.horizontal")
                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
        }
        .accessibilityLabel("Open history")
        .accessibilityHint("Shows your conversation list")
    }

    var newChatButton: some View {
        Button {
            Task { await chatStore.createNewConversation() }
        } label: {
            Label("New Chat", systemImage: "square.and.pencil")
        }
        .accessibilityHint("Starts a new conversation")
    }

    var toolsMenu: some View {
        Menu {
            newChatButton

            Divider()

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
                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open tools menu")
        .accessibilityHint("Opens voice, library, search, and settings options")
    }

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
            .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
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
        let provider = model.providerType.displayName
        return model.displayName.localizedStandardContains(provider)
            ? model.displayName
            : "\(provider). \(model.displayName)"
    }

    private var currentProviderType: AIProviderType {
        chatStore.currentModel?.providerType ?? .foundationModels
    }
}

private extension View {
    @ViewBuilder
    func toolbarSheetTransition(source: ToolbarSheetSource, namespace: Namespace.ID) -> some View {
        // Disabled for now: CI runs Xcode 16 SDK where zoom navigation transitions are unavailable.
        self
    }

    @ViewBuilder
    func lightweightSheetPresentation() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            self
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
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 56

    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        NavigationStack {
            VStack(spacing: LumenSpacing.lg) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: iconSize))
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
        .environment(MemoryStore.shared)
}

#Preview("Placeholder") {
    PlaceholderView(
        title: "Prompt Library",
        subtitle: "Quick actions and reusable prompts appear here.",
        icon: LumenIcon.library
    )
}
