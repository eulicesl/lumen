import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @State private var showingConversationList = false

    var body: some View {
        @Bindable var store = appStore
        TabView(selection: $store.selectedTab) {
            Tab("Chat", systemImage: LumenIcon.chat, value: LumenTab.chat) {
                NavigationStack {
                    ChatView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showingConversationList = true
                                } label: {
                                    Image(systemName: "sidebar.left")
                                }
                                .accessibilityLabel("Show Conversations")
                            }
                        }
                }
                .fullScreenCover(isPresented: $showingConversationList) {
                    ConversationPickerView()
                        .environment(chatStore)
                }
            }

            Tab("Voice", systemImage: LumenIcon.voice, value: LumenTab.voice) {
                VoiceInputView()
            }

            Tab("Library", systemImage: LumenIcon.library, value: LumenTab.library) {
                PromptLibraryView()
            }

            Tab("Search", systemImage: LumenIcon.search, value: LumenTab.search, role: .search) {
                SearchView()
            }

            Tab("Settings", systemImage: LumenIcon.settings, value: LumenTab.settings) {
                NavigationStack {
                    SettingsStoreView()
                }
            }
        }
        .background(Color(.systemBackground))
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
