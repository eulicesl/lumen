#if os(iOS)
import SwiftUI

struct iPadContentView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(MemoryStore.self) private var memoryStore
@SceneStorage("scene.selectedConversationID") private var restoredConversationID: String?
    @SceneStorage("scene.ipadColumnVisibility") private var restoredColumnVisibility = "all"
    @State private var columnVisibility: NavigationSplitViewVisibility = {
        AppLaunchConfiguration.isReleaseCaptureMode ? .detailOnly : .all
    }()
    @State private var showSettingsAsContent = false

    var body: some View {
        @Bindable var bindableStore = appStore
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if !showSettingsAsContent {
                ConversationListView()
                    .navigationSplitViewColumnWidth(min: 260, ideal: LumenLayout.sidebarWidthMac)
            }
        } detail: {
            if showSettingsAsContent {
                SettingsView()
                    .environment(appStore)
                    .environment(chatStore)
                    .environment(modelStore)
                    .environment(memoryStore)
            } else {
                ChatView()
            }
        }
        .task {
            if !AppLaunchConfiguration.isReleaseCaptureMode {
                restoreColumnVisibility()
            }
            await restoreSceneSelectionIfNeeded()
            if AppLaunchConfiguration.isReleaseCaptureMode {
                let isSettingsScene = AppLaunchConfiguration.screenshotScene?.opensSettings == true
                if isSettingsScene {
                    showSettingsAsContent = true
                }
            }
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
