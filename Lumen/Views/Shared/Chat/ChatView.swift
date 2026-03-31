import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isAtBottom = true
    @State private var showingComparison = false
    @State private var showingSystemPrompt = false

    var showsConversationTools: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if chatStore.selectedConversation == nil {
                    emptyConversationPrompt
                } else if chatStore.messages.isEmpty && chatStore.conversationState != .generating {
                    emptyMessagesPrompt
                } else {
                    messageList
                }
            }

            if showsScrollToBottomButton {
                scrollToBottomButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .animation(LumenAnimation.standard, value: showsScrollToBottomButton)
        .navigationTitle(chatStore.selectedConversation?.title ?? "Lumen")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if showsConversationTools {
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
            if let focusedMessageID = chatStore.focusedMessageID {
                scrollToMessage(focusedMessageID)
            } else {
                scrollToBottom()
            }
        }
        .onChange(of: chatStore.messages.last?.content) {
            if isAtBottom { scrollToBottom() }
        }
        .onChange(of: chatStore.focusedMessageID) {
            guard let focusedMessageID = chatStore.focusedMessageID else { return }
            scrollToMessage(focusedMessageID)
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
                                .searchFocusChrome(
                                    isFocused: chatStore.focusedMessageID == message.id
                                )
                        }
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                            .background(
                                GeometryReader { marker in
                                    Color.clear.preference(
                                        key: BottomMarkerMaxYKey.self,
                                        value: marker.frame(in: .named("messageScroll")).maxY
                                    )
                                }
                            )
                    }
                    .frame(minHeight: geo.size.height - LumenSpacing.md, alignment: .bottom)
                    .padding(.top, LumenSpacing.sm)
                    .padding(.bottom, LumenSpacing.sm)
                }
                .coordinateSpace(name: "messageScroll")
                .scrollDismissesKeyboard(.interactively)
                .onPreferenceChange(BottomMarkerMaxYKey.self) { maxY in
                    isAtBottom = maxY <= geo.size.height + LumenSpacing.xxl
                }
                .onAppear {
                    scrollProxy = proxy
                    if let focusedMessageID = chatStore.focusedMessageID {
                        scrollToMessage(focusedMessageID, animated: false)
                    } else {
                        scrollToBottom(animated: false)
                    }
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

    private var showsScrollToBottomButton: Bool {
        !isAtBottom && chatStore.messages.count > 1
    }

    private var scrollToBottomButton: some View {
        Button {
            chatStore.focusedMessageID = nil
            scrollToBottom()
        } label: {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white, Color.accentColor)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.trailing, LumenSpacing.lg)
        .padding(.bottom, LumenSpacing.xl)
        .accessibilityLabel("Scroll to latest message")
        .accessibilityHint("Jumps to the newest message in the conversation")
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func scrollToBottom(animated: Bool = true) {
        if animated {
            withAnimation(LumenAnimation.standard) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func scrollToMessage(_ messageID: UUID, animated: Bool = true) {
        if animated {
            withAnimation(LumenAnimation.standard) {
                scrollProxy?.scrollTo(messageID, anchor: .center)
            }
        } else {
            scrollProxy?.scrollTo(messageID, anchor: .center)
        }
    }
}

private struct BottomMarkerMaxYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension View {
    @ViewBuilder
    func searchFocusChrome(isFocused: Bool) -> some View {
        if isFocused {
            self
                .padding(.vertical, LumenSpacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.18), lineWidth: 1)
                )
        } else {
            self
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
