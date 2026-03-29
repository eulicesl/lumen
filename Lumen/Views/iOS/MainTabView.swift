import SwiftUI

struct MainTabView: View {

    @Environment(AppStore.self) private var appStore
    @Environment(ChatStore.self) private var chatStore
    @State private var showingConversationList = false

    var body: some View {
        @Bindable var store = appStore

        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer {
                    tabShell(selection: $store.selectedTab)
                }
            } else {
                tabShell(selection: $store.selectedTab)
            }
        }
    }

    @ViewBuilder
    private func tabShell(selection: Binding<LumenTab>) -> some View {
        TabView(selection: selection) {
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
                .sheet(isPresented: $showingConversationList) {
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
        .modifier(IOS26TabChrome(chatStore: chatStore))
    }
}

private struct IOS26TabChrome: ViewModifier {
    let chatStore: ChatStore

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    if chatStore.conversationState == .generating {
                        HStack(spacing: LumenSpacing.sm) {
                            ProgressView()
                                .controlSize(.small)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generating")
                                    .font(LumenType.caption)
                                    .fontWeight(.semibold)
                                Text(chatStore.currentModel?.displayName ?? "Current model")
                                    .font(LumenType.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            Button("Stop") {
                                chatStore.stopGeneration()
                            }
                            .buttonStyle(.borderless)
                            .font(LumenType.caption)
                        }
                        .padding(.horizontal, LumenSpacing.md)
                        .padding(.vertical, LumenSpacing.xs)
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: chatStore.conversationState == .generating)
        } else {
            content
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
