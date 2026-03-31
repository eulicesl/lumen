import Foundation

struct ConversationSearchResult: Identifiable {
    let id: UUID
    let section: SearchSection
    let title: String
    let subtitle: String
    let conversation: Conversation
    let matchedMessageID: UUID?

    var symbolName: String {
        matchedMessageID == nil ? LumenIcon.chat : "text.bubble"
    }
}

enum SearchSection: CaseIterable {
    case conversations, messages

    var label: String {
        switch self {
        case .conversations: return "Conversations"
        case .messages:      return "Messages"
        }
    }
}

enum ConversationSearchEngine {
    static let maxMessageMatchesPerConversation = 5

    static func search(
        _ rawQuery: String,
        in conversations: [Conversation]
    ) -> [ConversationSearchResult] {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        var results: [ConversationSearchResult] = []
        results.reserveCapacity(conversations.count * 2)

        for conversation in conversations {
            if conversation.title.localizedCaseInsensitiveContains(query) {
                results.append(
                    ConversationSearchResult(
                        id: conversation.id,
                        section: .conversations,
                        title: conversation.title,
                        subtitle: conversation.preview.isEmpty ? "No messages" : conversation.preview,
                        conversation: conversation,
                        matchedMessageID: nil
                    )
                )
            }

            var messageHitCount = 0
            for message in conversation.messages {
                guard !message.isSystem, !message.content.isEmpty else { continue }
                guard message.content.localizedCaseInsensitiveContains(query) else { continue }

                results.append(
                    ConversationSearchResult(
                        id: message.id,
                        section: .messages,
                        title: "\(conversation.title) · \(message.role.displayName)",
                        subtitle: highlightedExcerpt(from: message.content, around: query),
                        conversation: conversation,
                        matchedMessageID: message.id
                    )
                )

                messageHitCount += 1
                if messageHitCount == maxMessageMatchesPerConversation {
                    break
                }
            }
        }

        return results
    }

    static func highlightedExcerpt(
        from text: String,
        around query: String
    ) -> String {
        guard let range = text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(text.prefix(80))
        }

        let start = text.index(
            range.lowerBound,
            offsetBy: -20,
            limitedBy: text.startIndex
        ) ?? text.startIndex
        let end = text.index(
            range.upperBound,
            offsetBy: 60,
            limitedBy: text.endIndex
        ) ?? text.endIndex
        let slice = String(text[start..<end])

        return (start > text.startIndex ? "…" : "")
            + slice
            + (end < text.endIndex ? "…" : "")
    }
}
