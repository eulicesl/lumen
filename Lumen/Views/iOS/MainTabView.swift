import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore

    var body: some View {
        @Bindable var store = appStore
        TabView(selection: $store.selectedTab) {
            Tab("Chat", systemImage: LumenIcon.chat, value: LumenTab.chat) {
                NavigationSplitView {
                    ConversationListView()
                } detail: {
                    ChatView()
                }
            }

            Tab("Voice", systemImage: LumenIcon.voice, value: LumenTab.voice) {
                VoiceInputView()
            }

            Tab("Library", systemImage: LumenIcon.library, value: LumenTab.library) {
                PlaceholderView(
                    title: "Library",
                    subtitle: "Prompt templates coming in Phase 3",
                    icon: LumenIcon.library
                )
            }

            Tab("Search", systemImage: LumenIcon.search, role: .search, value: LumenTab.search) {
                PlaceholderView(
                    title: "Search",
                    subtitle: "Conversation search coming in Phase 3",
                    icon: LumenIcon.search
                )
            }

            Tab("Settings", systemImage: LumenIcon.settings, value: LumenTab.settings) {
                NavigationStack {
                    SettingsView()
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

#Preview {
    MainTabView()
        .environment(AppStore.shared)
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
}
