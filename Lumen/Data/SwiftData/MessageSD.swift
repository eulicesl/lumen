import SwiftData
import Foundation

@Model
final class MessageSD {
    var id: UUID = UUID()
    var content: String = ""
    var role: String = "user"
    var createdAt: Date = Date()
    var isComplete: Bool = true
    var isError: Bool = false
    var tokenCount: Int?

    @Attribute(.externalStorage)
    var imageData: [Data]?

    var conversation: ConversationSD?

    init(
        id: UUID = UUID(),
        content: String,
        role: String,
        createdAt: Date = Date(),
        isComplete: Bool = true,
        isError: Bool = false,
        tokenCount: Int? = nil,
        imageData: [Data]? = nil
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.createdAt = createdAt
        self.isComplete = isComplete
        self.isError = isError
        self.tokenCount = tokenCount
        self.imageData = imageData
    }

    func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            role: MessageRole(rawValue: role) ?? .user,
            content: content,
            createdAt: createdAt,
            isComplete: isComplete,
            isError: isError,
            tokenCount: tokenCount,
            imageData: imageData
        )
    }

    static func from(_ message: ChatMessage) -> MessageSD {
        MessageSD(
            id: message.id,
            content: message.content,
            role: message.role.rawValue,
            createdAt: message.createdAt,
            isComplete: message.isComplete,
            isError: message.isError,
            tokenCount: message.tokenCount,
            imageData: message.imageData
        )
    }
}
