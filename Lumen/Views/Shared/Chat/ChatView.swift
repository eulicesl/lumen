import SwiftUI

struct ChatView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isAtBottom = true
    @State private var showingComparison = false
    @State private var showingSystemPrompt = false
    @ScaledMetric(relativeTo: .title) private var emptyPromptSymbolSize = 56
    @ScaledMetric(relativeTo: .title3) private var scrollButtonIconSize = 28

    var showsConversationTools: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
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
        .background(LumenColor.primaryBackground)
        .animation(
            LumenMotion.animation(LumenAnimation.standard, reduceMotion: reduceMotion),
            value: showsScrollToBottomButton
        )
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
                            .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                    }
                    .help(conv.hasSystemPrompt ? "Edit System Prompt" : "Set System Prompt")
                    .accessibilityLabel(conv.hasSystemPrompt ? "Edit system prompt" : "Set system prompt")
                    .accessibilityHint("Opens system prompt settings for this conversation")
                    }
                }

                if !chatStore.exportText.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: chatStore.exportText) {
                            Image(systemName: LumenIcon.share)
                                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                        }
                        .help("Share conversation")
                        .accessibilityLabel("Share conversation")
                        .accessibilityHint("Opens the share sheet for this conversation")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingComparison = true
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                    }
                    .help("Compare Models")
                    .accessibilityLabel("Compare Models")
                    .accessibilityHint("Opens model comparison for the current conversation")
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if chatStore.selectedConversation != nil {
                InputBarView()
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
                            MessageBubbleView(
                                message: message,
                                availableWidth: geo.size.width - (LumenSpacing.md * 2)
                            )
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
            emptyPromptSymbol

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

            if !starterPrompts.isEmpty {
                starterPromptSection
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

    private var starterPromptSection: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm) {
            Text("Start with a prompt")
                .font(LumenType.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: LumenSpacing.sm) {
                    ForEach(starterPrompts) { prompt in
                        StarterPromptCard(prompt: prompt) {
                            applyStarterPrompt(prompt)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LumenSpacing.sm) {
                        ForEach(starterPrompts) { prompt in
                            StarterPromptCard(prompt: prompt) {
                                applyStarterPrompt(prompt)
                            }
                        }
                    }
                    .padding(.vertical, LumenSpacing.xxs)
                }
            }
        }
        .frame(maxWidth: 640, alignment: .leading)
    }

    private var scrollToBottomButton: some View {
        Button {
            chatStore.focusedMessageID = nil
            scrollToBottom()
        } label: {
            Label("Latest", systemImage: "arrow.down")
                .font(LumenType.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, LumenSpacing.md)
                .padding(.vertical, LumenSpacing.sm)
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(LumenColor.separator.opacity(0.35), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.10), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.bottom, LumenSpacing.xl)
        .accessibilityLabel("Scroll to latest message")
        .accessibilityHint("Jumps to the newest message in the conversation")
        .transition(LumenMotion.moveTransition(edge: .bottom, reduceMotion: reduceMotion))
    }

    private var starterPrompts: [SavedPrompt] {
        SavedPrompt.starterPrompts
    }

    private func applyStarterPrompt(_ prompt: SavedPrompt) {
        chatStore.inputText = prompt.content
        chatStore.focusedMessageID = nil
        HapticEngine.impact(.light)
    }

    private func scrollToBottom(animated: Bool = true) {
        if animated {
            LumenMotion.perform(LumenAnimation.standard, reduceMotion: reduceMotion) {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            scrollProxy?.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func scrollToMessage(_ messageID: UUID, animated: Bool = true) {
        if animated {
            LumenMotion.perform(LumenAnimation.standard, reduceMotion: reduceMotion) {
                scrollProxy?.scrollTo(messageID, anchor: .center)
            }
        } else {
            scrollProxy?.scrollTo(messageID, anchor: .center)
        }
    }

    @ViewBuilder
    private var emptyPromptSymbol: some View {
        let symbol = Image(systemName: "sparkle")
            .font(.system(size: emptyPromptSymbolSize))
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)

        if reduceMotion {
            symbol
        } else {
            symbol.symbolEffect(.pulse.wholeSymbol)
        }
    }
}

private struct StarterPromptCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let prompt: SavedPrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LumenSpacing.sm) {
                Label(prompt.category.rawValue, systemImage: prompt.category.icon)
                    .font(LumenType.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(prompt.title)
                    .font(LumenType.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(promptPreview)
                    .font(LumenType.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 3)
            }
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 220, alignment: .leading)
            .padding(LumenSpacing.md)
            .glassCard(radius: LumenRadius.lg, interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(prompt.title)
        .accessibilityValue(promptPreview)
        .accessibilityHint("Inserts this starter prompt into the composer")
    }

    private var promptPreview: String {
        prompt.content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? prompt.content
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
