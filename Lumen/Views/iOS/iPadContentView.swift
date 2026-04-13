#if os(iOS)
import SwiftUI

struct iPadContentView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(MemoryStore.self) private var memoryStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SceneStorage("scene.selectedConversationID") private var restoredConversationID: String?
    @SceneStorage("scene.ipadColumnVisibility") private var restoredColumnVisibility = "all"
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var bindableStore = appStore
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationListView()
                .navigationSplitViewColumnWidth(min: 260, ideal: LumenLayout.sidebarWidthMac)
        } detail: {
            ChatView()
                .toolbar {
                    if !AppLaunchConfiguration.isReleaseCaptureMode {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                LumenMotion.perform(.easeInOut(duration: 0.2), reduceMotion: reduceMotion) {
                                    columnVisibility = columnVisibility == .all ? .detailOnly : .all
                                }
                            } label: {
                                Image(systemName: "sidebar.left")
                            }
                            .accessibilityLabel(columnVisibility == .all ? "Hide Conversations" : "Show Conversations")
                        }
                    }
                }
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsView()
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

private extension iPadContentView {
    func restoreSceneSelectionIfNeeded() async {
        let restoredID = restoredConversationID.flatMap(UUID.init(uuidString:))
        await chatStore.restoreSelectedConversation(id: restoredID)
    }

    func restoreColumnVisibility() {
        if AppLaunchConfiguration.isReleaseCaptureMode {
            columnVisibility = .detailOnly
            return
        }

        columnVisibility = NavigationSplitViewVisibility(
            sceneStorageValue: restoredColumnVisibility,
            fallback: .all
        )
    }
}

#Preview {
    iPadContentView()
        .environment(AppStore.shared)
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
        .environment(MemoryStore.shared)
}
#endif
