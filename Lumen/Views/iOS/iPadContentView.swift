#if os(iOS)
import SwiftUI

struct iPadContentView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var bindableStore = appStore
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationListView()
                .navigationSplitViewColumnWidth(min: 260, ideal: LumenLayout.sidebarWidthMac)
        } detail: {
            ChatView()
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            SettingsStoreView()
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
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

