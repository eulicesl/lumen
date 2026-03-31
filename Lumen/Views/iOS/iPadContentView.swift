#if os(iOS)
import SwiftUI

struct iPadContentView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
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
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                columnVisibility = columnVisibility == .all ? .detailOnly : .all
                            }
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                        .accessibilityLabel(columnVisibility == .all ? "Hide Conversations" : "Show Conversations")
                    }
                }
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsStoreView(showsDoneButton: true)
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
        }
        .task {
            restoreColumnVisibility()
            await restoreSceneSelectionIfNeeded()
        }
        .onChange(of: chatStore.conversations.map { $0.id.uuidString }) {
            Task { await restoreSceneSelectionIfNeeded() }
        }
        .onChange(of: chatStore.selectedConversation?.id.uuidString) {
            restoredConversationID = chatStore.selectedConversation?.id.uuidString
        }
        .onChange(of: columnVisibility) {
            restoredColumnVisibility = sceneStorageValue(for: columnVisibility)
        }
    }
}

private extension iPadContentView {
    func restoreSceneSelectionIfNeeded() async {
        let restoredID = restoredConversationID.flatMap(UUID.init(uuidString:))
        await chatStore.restoreSelectedConversation(id: restoredID)
    }

    func restoreColumnVisibility() {
        switch restoredColumnVisibility {
        case "detailOnly":
            columnVisibility = .detailOnly
        case "automatic":
            columnVisibility = .automatic
        default:
            columnVisibility = .all
        }
    }

    func sceneStorageValue(for visibility: NavigationSplitViewVisibility) -> String {
        switch visibility {
        case .detailOnly:
            return "detailOnly"
        case .automatic:
            return "automatic"
        default:
            return "all"
        }
    }
}

#Preview {
    iPadContentView()
        .environment(AppStore.shared)
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
}
#endif
