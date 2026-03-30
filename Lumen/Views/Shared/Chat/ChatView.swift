import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isAtBottom = true
    @State private var showingComparison = false
    @State private var showingSystemPrompt = false

    var body: some View {
        VStack(spacing: 0) {
            if chatStore.selectedConversation == nil {
                emptyConversationPrompt
            } else if chatStore.messages.isEmpty && chatStore.conversationState != .generating {
                emptyMessagesPrompt
            } else {
                messageList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .navigationTitle(chatStore.selectedConversation?.title ?? "Lumen")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let conv = chatStore.selectedConversation {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSystemPrompt = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(conv.hasSystemPrompt ? Color.accentColor : Color.secondary)
                    }
                    .help(conv.hasSystemPrompt ? "Edit System Prompt" : "Set System Prompt")
                    .accessibilityLabel(conv.hasSystemPrompt ? "Edit system prompt" : "Set system prompt")
                }
            }

            if !chatStore.exportText.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: chatStore.exportText) {
                        Image(systemName: LumenIcon.share)
                    }
                    .help("Share conversation")
                    .accessibilityLabel("Share conversation")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComparison = true
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle")
                }
                .help("Compare Models")
                .accessibilityLabel("Compare Models")
            }
        }
        .sheet(isPresented: $showingComparison) {
            ModelComparisonView()
                .environment(chatStore)
                .environment(modelStore)
        }
        .sheet(isPresented: $showingSystemPrompt) {
            if let conv = chatStore.selectedConversation {
                SystemPromptSheet(conversation: conv)
                    .environment(chatStore)
            }
        }
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
            GeometryReader { geo in
                ScrollView {
                    LazyVStack(spacing: LumenSpacing.sm) {
                        ForEach(chatStore.messages) { message in
                            MessageBubbleView(message: message)
                                .padding(.horizontal, LumenSpacing.md)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .frame(minHeight: geo.size.height - LumenSpacing.md, alignment: .bottom)
                    .padding(.top, LumenSpacing.sm)
                    .padding(.bottom, LumenSpacing.sm)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(animated: false)
                }
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
            Image(systemName: "sparkle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse.wholeSymbol)

            VStack(spacing: LumenSpacing.sm) {
                Text("What can I help with?")
                    .font(LumenType.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let model = chatStore.currentModel {
                    Text("Using \(model.displayName)")
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 96)
        .padding(.horizontal, LumenSpacing.lg)
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
            .environment(ModelStore.shared)
    }
}
