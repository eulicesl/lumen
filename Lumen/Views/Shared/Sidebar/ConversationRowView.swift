import SwiftUI

struct ConversationRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let conversation: Conversation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: LumenSpacing.sm) {
            VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.title)
                        .font(LumenType.bodyBold)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    Spacer()
                    if conversation.isPinned {
                        Image(systemName: LumenIcon.pin)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    Text(conversation.updatedAt.relativeTimeString)
                        .font(LumenType.caption)
                        .foregroundStyle(.tertiary)
                }
                if !conversation.preview.isEmpty {
                    Text(conversation.preview)
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                }
            }
        }
        .padding(.vertical, LumenSpacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(conversation.title)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Opens this conversation")
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if conversation.isPinned {
            parts.append("Pinned")
        }
        if !conversation.preview.isEmpty {
            parts.append(conversation.preview)
        }
        parts.append("Updated \(conversation.updatedAt.relativeTimeString)")
        if isSelected {
            parts.append("Selected")
        }
        return parts.joined(separator: ". ")
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
