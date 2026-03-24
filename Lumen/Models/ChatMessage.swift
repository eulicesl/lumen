import Foundation

struct ChatMessage: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var role: MessageRole
    var content: String
    let createdAt: Date
    var isComplete: Bool
    var isError: Bool
    var tokenCount: Int?
    var imageData: [Data]?
    var model: AIModel?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        createdAt: Date = Date(),
        isComplete: Bool = true,
        isError: Bool = false,
        tokenCount: Int? = nil,
        imageData: [Data]? = nil,
        model: AIModel? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.isComplete = isComplete
        self.isError = isError
        self.tokenCount = tokenCount
        self.imageData = imageData
        self.model = model
    }

    var isUser: Bool { role == .user }
    var isAssistant: Bool { role == .assistant }
    var isSystem: Bool { role == .system }

    var hasImages: Bool { !(imageData?.isEmpty ?? true) }
    var isStreaming: Bool { role == .assistant && !isComplete && !isError }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ChatMessage {
    static func userMessage(_ content: String, imageData: [Data]? = nil) -> ChatMessage {
        ChatMessage(role: .user, content: content, imageData: imageData)
    }

    static func assistantMessage(_ content: String, model: AIModel? = nil, tokenCount: Int? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, tokenCount: tokenCount, model: model)
    }

    static func systemMessage(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content)
    }

    static func streamingPlaceholder(model: AIModel? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: "", isComplete: false, model: model)
    }

    static func errorMessage(_ errorDescription: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: errorDescription, isComplete: true, isError: true)
    }
}
