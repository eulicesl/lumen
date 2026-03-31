import SwiftUI

#if os(macOS)
struct MacContentView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(MemoryStore.self) private var memoryStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SceneStorage("scene.selectedConversationID") private var restoredConversationID: String?
    @SceneStorage("scene.macColumnVisibility") private var restoredColumnVisibility = "automatic"
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        @Bindable var bindableStore = appStore
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationListView()
                .navigationSplitViewColumnWidth(min: 220, ideal: LumenLayout.sidebarWidthMac)
        } detail: {
            ChatView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    LumenMotion.perform(LumenAnimation.standard, reduceMotion: reduceMotion) {
                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    }
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await ChatStore.shared.createNewConversation() }
                } label: {
                    Label("New Conversation", systemImage: LumenIcon.newChat)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { appStore.showingSettings = true } label: {
                    Label("Settings", systemImage: LumenIcon.settings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsStoreView(showsDoneButton: true)
                .frame(minWidth: 480, minHeight: 560)
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
                .environment(memoryStore)
        }
        .task {
            restoreColumnVisibility()
            await restoreSceneSelectionIfNeeded()
        }
        .onChange(of: chatStore.conversations.count) {
            Task { await restoreSceneSelectionIfNeeded() }
        }
        .onChange(of: chatStore.selectedConversation?.id.uuidString) {
            restoredConversationID = chatStore.selectedConversation?.id.uuidString
        }
        .onChange(of: columnVisibility) {
            restoredColumnVisibility = columnVisibility.sceneStorageValue
        }
    }
}

private extension MacContentView {
    func restoreSceneSelectionIfNeeded() async {
        let restoredID = restoredConversationID.flatMap(UUID.init(uuidString:))
        await chatStore.restoreSelectedConversation(id: restoredID)
    }

    func restoreColumnVisibility() {
        columnVisibility = NavigationSplitViewVisibility(
            sceneStorageValue: restoredColumnVisibility,
            fallback: .automatic
        )
    }
}

#Preview {
    MacContentView()
        .environment(AppStore.shared)
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
        .environment(MemoryStore.shared)
        .frame(width: 900, height: 600)
}
#endif
