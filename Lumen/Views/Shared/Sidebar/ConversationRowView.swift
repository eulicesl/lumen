import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: LumenSpacing.sm) {
            VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                HStack {
                    Text(conversation.title)
                        .font(LumenType.bodyBold)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.isPinned {
                        Image(systemName: LumenIcon.pin)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Text(conversation.updatedAt.relativeTimeString)
                        .font(LumenType.caption)
                        .foregroundStyle(.tertiary)
                }
                if !conversation.preview.isEmpty {
                    Text(conversation.preview)
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, LumenSpacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Font helper

private extension LumenType {
    static var bodyBold: Font { .system(.body, design: .default, weight: .medium) }
}

#Preview {
    List {
        ConversationRowView(
            conversation: Conversation(title: "Planning my vacation", messages: [
                .userMessage("Help me plan a trip to Japan"),
                .assistantMessage("Great choice! Japan has amazing…")
            ]),
            isSelected: false
        )
        ConversationRowView(
            conversation: Conversation(title: "Swift concurrency explained", isPinned: true),
            isSelected: true
        )
    }
}
