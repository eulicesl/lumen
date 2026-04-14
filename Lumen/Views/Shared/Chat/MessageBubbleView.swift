import SwiftUI
import AVFoundation
#if os(iOS)
import UIKit
#endif

struct MessageBubbleView: View {
    let message: ChatMessage
    let availableWidth: CGFloat?
    @Environment(ChatStore.self) private var chatStore

    init(message: ChatMessage, availableWidth: CGFloat? = nil) {
        self.message = message
        self.availableWidth = availableWidth
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var thinkingExpanded = false
    @State private var showingBranchConfirm = false
    @State private var showingCopyFeedback = false
    @State private var copyFeedbackTask: Task<Void, Never>?
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    private var canRegenerateMessage: Bool {
        chatStore.canRegenerate && chatStore.messages.last?.id == message.id
    }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: LumenSpacing.xs) {
            if message.isAssistant, !thinkBlocks.isEmpty {
                thinkingDisclosure
            }

            if let images = message.imageData, !images.isEmpty {
                MessageImageGrid(imageData: images)
            }

            if !message.content.isEmpty || message.isStreaming {
                bubbleContent
                    .contextMenu { contextMenuItems }
                    .modifier(
                        MessageAccessibilityActions(
                            message: message,
                            canRegenerate: canRegenerateMessage,
                            onCopy: copyMessage,
                            onSaveToMemory: saveToMemory,
                            onRegenerate: regenerateMessage,
                            onBranch: { showingBranchConfirm = true },
                            onSpeak: speakMessage,
                            onEdit: { chatStore.beginEditing(message) }
                        )
                    )
            }

            if showingCopyFeedback {
                copyFeedbackBadge
            }

            if message.isAssistant, message.isComplete, let count = message.tokenCount, count > 0 {
                Text("\(count) tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, LumenSpacing.sm)
                    .offset(y: -2)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .id(message.id)
        .confirmationDialog(
            "Branch from this message?",
            isPresented: $showingBranchConfirm,
            titleVisibility: .visible
        ) {
            Button("Create Branch") {
                Task { await chatStore.branchFrom(message: message) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A new conversation will be created with all messages up to and including this one.")
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyMessage()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        if message.isComplete && !message.isError {
            if canRegenerateMessage {
                Button {
                    regenerateMessage()
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }

            Button {
                showingBranchConfirm = true
            } label: {
                Label("Branch from Here", systemImage: "arrow.branch")
            }
        }

        if message.isAssistant, !message.content.isEmpty {
            Button {
                speakMessage()
            } label: {
                Label("Speak", systemImage: "speaker.wave.2")
            }
        }

        if message.isUser && !message.content.isEmpty && !message.hasImages {
            Button {
                chatStore.beginEditing(message)
            } label: {
                Label("Edit & Resend", systemImage: "pencil")
            }
        }

        Divider()

        Button {
            saveToMemory()
        } label: {
            Label("Save to Memory", systemImage: "brain.head.profile")
        }
    }

    // MARK: - Bubble content

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isStreaming {
            streamingContent
                .bubbleBackground(isUser: false, isError: false)
                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
        } else if message.isError {
            errorContent
                .bubbleBackground(isUser: false, isError: true)
                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
        } else if message.isAssistant && mainContent.hasCodeBlocks {
            // Mixed text + code: no outer bubble; code blocks break out to full-width dark panels
            MessageContentView(text: mainContent, maxWidth: maxBubbleWidth)
        } else {
            plainRenderedContent
                .bubbleBackground(isUser: message.isUser, isError: false)
                .frame(maxWidth: maxBubbleWidth, alignment: message.isUser ? .trailing : .leading)
        }
    }

    private var plainRenderedContent: some View {
        let displayText = message.isAssistant ? mainContent : message.content.documentAwareDisplayText

        if message.isUser {
            return AnyView(
                Text(AttributedString.fromMarkdown(displayText))
                    .font(LumenType.messageBody)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)
            )
        } else {
            return AnyView(
                Text(AttributedString.fromMarkdown(displayText))
                    .font(LumenType.messageBody)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)
            )
        }
    }

    private var streamingContent: some View {
        HStack(spacing: 0) {
            if message.content.isEmpty {
                TypingIndicator()
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
            } else {
                Text(AttributedString.fromMarkdown(mainContent))
                    .font(LumenType.messageBody)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)
                StreamingPulse()
                    .padding(.trailing, LumenSpacing.sm)
            }
        }
    }

    private var errorContent: some View {
        HStack(spacing: LumenSpacing.xs) {
            Image(systemName: LumenIcon.warning)
                .foregroundStyle(.red)
            Text(message.content)
                .font(LumenType.messageBody)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.sm)
    }

    // MARK: - Think blocks

    private var thinkBlocks: [String] { message.content.extractThinkBlocks() }

    /// Agent markup is already sanitized during agent streaming before it
    /// reaches normal assistant rendering. Keep display logic conservative here
    /// so literal examples like [[TOOL:...]] are not removed from valid answers.
    private var mainContent: String {
        message.content.stripThinkBlocks()
    }

    private var thinkingDisclosure: some View {
        DisclosureGroup(isExpanded: $thinkingExpanded) {
            VStack(alignment: .leading, spacing: LumenSpacing.xs) {
                ForEach(thinkBlocks, id: \.self) { block in
                    Text(block)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, LumenSpacing.xs)
        } label: {
            Label("Thinking", systemImage: "brain")
                .font(LumenType.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.xs)
        .glassCard(radius: LumenRadius.md)
    }

    // MARK: - Actions

    private func copyMessage() {
        let copiedContent = message.isUser ? message.content.documentAwareDisplayText : mainContent
        #if os(iOS)
        UIPasteboard.general.string = copiedContent
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(copiedContent, forType: .string)
        #endif
        HapticEngine.impact(.light)
        showCopyConfirmation()
    }

    private func speakMessage() {
        let text = mainContent.isEmpty ? message.content : mainContent
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier)
        utterance.rate = 0.52
        if speechSynthesizer.isSpeaking { speechSynthesizer.stopSpeaking(at: .immediate) }
        speechSynthesizer.speak(utterance)
    }

    private func saveToMemory() {
        let text = message.isUser ? message.content.documentAwareDisplayText : mainContent
        let shortened = String(text.prefix(200))
        MemoryStore.shared.add(content: shortened, category: message.isUser ? .preference : .fact)
    }

    private func regenerateMessage() {
        guard canRegenerateMessage else { return }
        Task { await chatStore.regenerate() }
    }

    private var maxBubbleWidth: CGFloat {
        #if os(iOS)
        let layoutWidth = availableWidth ?? UIScreen.main.bounds.width
        let usableWidth = max(layoutWidth, 280)

        if message.isUser {
            return max(180, min(usableWidth * 0.64, 360))
        } else {
            return max(220, min(usableWidth * 0.70, 400))
        }
        #else
        let layoutWidth = availableWidth ?? 720
        if message.isUser {
            return max(260, min(layoutWidth * 0.72, 520))
        } else {
            return max(320, min(layoutWidth * 0.82, 760))
        }
        #endif
    }

    private var copyFeedbackBadge: some View {
        Label("Copied", systemImage: "checkmark")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.green)
            .padding(.horizontal, LumenSpacing.sm)
            .padding(.vertical, LumenSpacing.xxs)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.green.opacity(0.18), lineWidth: 1)
            )
            .transition(
                LumenMotion.moveTransition(
                    edge: message.isUser ? .trailing : .leading,
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityLabel("Copied")
    }

    private func showCopyConfirmation() {
        copyFeedbackTask?.cancel()

        LumenMotion.perform(LumenAnimation.fade, reduceMotion: reduceMotion) {
            showingCopyFeedback = true
        }

        copyFeedbackTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_200_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            LumenMotion.perform(LumenAnimation.fade, reduceMotion: reduceMotion) {
                showingCopyFeedback = false
            }
        }
    }
}

private struct MessageAccessibilityActions: ViewModifier {
    let message: ChatMessage
    let canRegenerate: Bool
    let onCopy: () -> Void
    let onSaveToMemory: () -> Void
    let onRegenerate: () -> Void
    let onBranch: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(baseHint)
            .accessibilityAction(named: Text("Copy"), onCopy)
            .accessibilityAction(named: Text("Save to Memory"), onSaveToMemory)
            .messageAction(
                isEnabled: canRegenerate,
                name: "Regenerate",
                action: onRegenerate
            )
            .messageAction(
                isEnabled: message.isComplete && !message.isError,
                name: "Branch from Here",
                action: onBranch
            )
            .messageAction(
                isEnabled: message.isAssistant && !message.content.isEmpty,
                name: "Speak",
                action: onSpeak
            )
            .messageAction(
                isEnabled: message.isUser && !message.content.isEmpty && !message.hasImages,
                name: "Edit & Resend",
                action: onEdit
            )
    }

    private var accessibilityLabel: String {
        if message.isError {
            return "Assistant response failed"
        }

        if message.isStreaming {
            return "Assistant is responding"
        }

        return message.isUser ? "You said" : "Assistant replied"
    }

    private var accessibilityValue: String {
        if message.isError {
            return message.content
        }

        if message.isUser {
            let value = message.content.documentAwareDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "Empty message" : value
        }

        let value = message.content.stripThinkBlocks().trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "No spoken content" : value
    }

    private var baseHint: String {
        if message.isStreaming {
            return "Custom actions are available for copying or saving this message"
        }

        return "Open custom actions for copy, save, and message actions"
    }
}

// MARK: - Bubble background modifier

private struct BubbleBackground: ViewModifier {
    let isUser: Bool
    let isError: Bool

    func body(content: Content) -> some View {
        if isUser {
            content
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: LumenRadius.bubble))
        } else if isError {
            content
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: LumenRadius.bubble))
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.bubble)
                        .strokeBorder(Color.red.opacity(0.32), lineWidth: 1)
                )
        } else {
            content
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: LumenRadius.bubble))
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.bubble)
                        .strokeBorder(Color(.separator).opacity(0.38), lineWidth: 0.5)
                )
        }
    }
}

private extension View {
    func bubbleBackground(isUser: Bool, isError: Bool) -> some View {
        modifier(BubbleBackground(isUser: isUser, isError: isError))
    }

    @ViewBuilder
    func messageAction(isEnabled: Bool, name: String, action: @escaping () -> Void) -> some View {
        if isEnabled {
            accessibilityAction(named: Text(name), action)
        } else {
            self
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: LumenSpacing.md) {
            MessageBubbleView(message: .userMessage("Hello! How are you today?"))
            MessageBubbleView(message: .assistantMessage("I'm doing great, thanks for asking! How can I help you?"))
            MessageBubbleView(message: .streamingPlaceholder())
            MessageBubbleView(message: .errorMessage("Something went wrong. Please try again."))
        }
        .padding()
    }
    .environment(ChatStore.shared)
    .environment(AppStore.shared)
}
