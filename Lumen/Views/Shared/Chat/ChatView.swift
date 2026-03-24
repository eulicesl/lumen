import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isAtBottom = true

    var body: some View {
        VStack(spacing: 0) {
            if chatStore.selectedConversation == nil {
                emptyConversationPrompt
            } else if chatStore.messages.isEmpty && chatStore.conversationState != .generating {
                emptyMessagesPrompt
            } else {
                messageList
            }
            InputBarView()
        }
        .navigationTitle(chatStore.selectedConversation?.title ?? "Lumen")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: chatStore.messages.count) {
            scrollToBottom()
        }
        .onChange(of: chatStore.messages.last?.content) {
            if isAtBottom { scrollToBottom() }
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: LumenSpacing.md) {
                    ForEach(chatStore.messages) { message in
                        MessageBubbleView(message: message)
                            .padding(.horizontal, LumenSpacing.md)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.top, LumenSpacing.md)
                .padding(.bottom, LumenSpacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(animated: false)
            }
        }
    }

    // MARK: - Empty states

    private var emptyConversationPrompt: some View {
        ContentUnavailableView {
            Label("No Conversation Selected", systemImage: LumenIcon.chat)
        } description: {
            Text("Choose a conversation from the sidebar, or start a new one.")
        } actions: {
            Button("New Conversation") {
                Task { await chatStore.createNewConversation() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessagesPrompt: some View {
        VStack(spacing: LumenSpacing.xl) {
            Spacer()
            Image(systemName: "sparkle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse.wholeSymbol)
            VStack(spacing: LumenSpacing.sm) {
                Text("What can I help with?")
                    .font(LumenType.largeTitle)
                    .fontWeight(.bold)
                if let model = chatStore.currentModel {
                    Text("Using \(model.displayName)")
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func scrollToBottom(animated: Bool = true) {
        if animated {
            withAnimation(LumenAnimation.standard) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
            .environment(ChatStore.shared)
            .environment(AppStore.shared)
    }
}
