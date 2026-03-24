import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var thinkingExpanded = false

    var body: some View {
        HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: LumenSpacing.xs) {
                if message.isAssistant, !thinkBlocks.isEmpty {
                    thinkingDisclosure
                }
                bubbleContent
                    .bubbleBackground(isUser: message.isUser, isError: message.isError)

                if message.isAssistant, message.isComplete, let count = message.tokenCount, count > 0 {
                    Text("\(count) tokens")
                        .font(LumenType.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, LumenSpacing.xs)
                }
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
        .id(message.id)
    }

    // MARK: - Bubble content

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isStreaming {
            streamingContent
        } else if message.isError {
            errorContent
        } else {
            renderedContent
        }
    }

    private var renderedContent: some View {
        let displayText = message.isAssistant ? mainContent : message.content
        return Text(AttributedString.fromMarkdown(displayText))
            .font(LumenType.messageBody)
            .foregroundStyle(message.isUser ? Color.white : Color.primary)
            .textSelection(.enabled)
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.sm)
            .frame(maxWidth: LumenLayout.maxBubbleWidth, alignment: message.isUser ? .trailing : .leading)
    }

    private var streamingContent: some View {
        HStack(spacing: 0) {
            if message.content.isEmpty {
                TypingIndicator()
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
            } else {
                Text(AttributedString.fromMarkdown(message.content))
                    .font(LumenType.messageBody)
                    .foregroundStyle(Color.primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.sm)
                    .frame(maxWidth: LumenLayout.maxBubbleWidth, alignment: .leading)
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
        .frame(maxWidth: LumenLayout.maxBubbleWidth, alignment: .leading)
    }

    // MARK: - Think blocks

    private var thinkBlocks: [String] { message.content.extractThinkBlocks() }
    private var mainContent: String { message.content.stripThinkBlocks() }

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
        .glassBackground()
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.md))
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
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                )
        } else {
            content
                .glassBackground()
                .clipShape(RoundedRectangle(cornerRadius: LumenRadius.bubble))
        }
    }
}

private extension View {
    func bubbleBackground(isUser: Bool, isError: Bool) -> some View {
        modifier(BubbleBackground(isUser: isUser, isError: isError))
    }

    func glassBackground() -> some View {
        self.background(.regularMaterial)
    }
}

// MARK: - Layout constant

private extension LumenLayout {
    static var maxBubbleWidth: CGFloat { 600 }
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
    .environment(AppStore.shared)
}
