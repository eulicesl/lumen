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

    var body: some View {
        @Bindable var bindableStore = appStore

        NavigationStack {
            ChatView(showsConversationTools: true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingConversationList = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                        .accessibilityLabel("Open history")
                        .accessibilityHint("Shows your conversation list")
                    }

                    ToolbarItem(placement: .principal) {
                        ModelPickerChip()
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

    var body: some View {
        Menu {
            ForEach(modelStore.availableModels, id: \.id) { model in
                Button {
                    modelStore.selectModel(model)
                } label: {
                    HStack {
                        Text(model.displayName)
                        if chatStore.currentModel?.id == model.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(chatStore.currentModel?.shortName ?? "Model")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .liquidCapsuleChrome()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current model")
        .accessibilityValue(chatStore.currentModel?.displayName ?? "No model selected")
        .accessibilityHint("Double-tap to choose a different model")
        .task {
            if modelStore.availableModels.isEmpty {
                await modelStore.loadModels()
            }
        }
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
    @Environment(ChatStore.self) private var chatStore

    var body: some View {
        VStack(spacing: 0) {
            if chatStore.canRegenerate {
                regenerateBar
            }
            InputBarView()
        }
    }

    private var regenerateBar: some View {
        Button {
            Task { await chatStore.regenerate() }
        } label: {
            Label("Regenerate response", systemImage: "arrow.clockwise")
                .font(LumenType.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Regenerate response")
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.xs)
        .liquidRegenerateSurface()
    }
}

private extension View {
    @ViewBuilder
    func liquidRegenerateSurface() -> some View {
        if #available(iOS 26.0, *) {
            self.glassCard(radius: LumenRadius.md, interactive: true)
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
        }
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
