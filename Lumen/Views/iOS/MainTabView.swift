import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @State private var showingConversationList = false

    var body: some View {
        @Bindable var store = appStore
        TabView(selection: $store.selectedTab) {
            Tab("Chat", systemImage: LumenIcon.chat, value: LumenTab.chat) {
                ChatTabRoot(showingConversationList: $showingConversationList)
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
        .applyiOS26TabChrome(using: store.selectedTab, showChatAccessory: !showingConversationList)
        .background(Color(.systemBackground))
    }
}

private struct ChatTabRoot: View {
    @Binding var showingConversationList: Bool
    @Environment(ChatStore.self) private var chatStore

    var body: some View {
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
                .navigationDestination(isPresented: $showingConversationList) {
                    ConversationListView()
                        .environment(chatStore)
                        .navigationTitle("Lumen")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                }
                .chatComposerFallbackInset()
        }
    }
}

private extension View {
    @ViewBuilder
    func applyiOS26TabChrome(using selectedTab: LumenTab, showChatAccessory: Bool) -> some View {
        if #available(iOS 26.0, *) {
            self
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    if selectedTab == .chat && showChatAccessory {
                        ChatComposerChrome()
                    }
                }
        } else {
            self
        }
    }

    @ViewBuilder
    func chatComposerFallbackInset() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            self.safeAreaInset(edge: .bottom) {
                ChatComposerChrome()
            }
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
        .chatRegenerateBackground()
    }
}

private extension View {
    @ViewBuilder
    func chatRegenerateBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.interactive(),
                in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
            )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
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
