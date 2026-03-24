import SwiftData
import Foundation

@Model
final class ConversationSD {
    #Unique([\.id])

    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPinned: Bool = false
    var systemPrompt: String?

    @Relationship(deleteRule: .cascade, inverse: \MessageSD.conversation)
    var messages: [MessageSD] = []

    @Relationship(deleteRule: .nullify)
    var model: AIModelSD?

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        systemPrompt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.systemPrompt = systemPrompt
    }

    var preview: String {
        messages
            .filter { $0.role != "system" }
            .last?.content
            .prefix(100)
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func toDomain() -> Conversation {
        Conversation(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned,
            systemPrompt: systemPrompt,
            model: model?.toDomain(),
            messages: messages
                .sorted { $0.createdAt < $1.createdAt }
                .map { $0.toDomain() }
        )
    }
}
