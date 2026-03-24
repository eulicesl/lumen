import Foundation

struct Conversation: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var systemPrompt: String?
    var model: AIModel?
    var messages: [ChatMessage]

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        systemPrompt: String? = nil,
        model: AIModel? = nil,
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.systemPrompt = systemPrompt
        self.model = model
        self.messages = messages
    }

    var lastMessage: ChatMessage? {
        messages.last(where: { !$0.isSystem })
    }

    var preview: String {
        String(lastMessage?.content.prefix(100) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var messageCount: Int { messages.count }

    var hasSystemPrompt: Bool { systemPrompt != nil && !(systemPrompt?.isEmpty ?? true) }

    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Conversation {
    static func new(title: String = "New Conversation", model: AIModel? = nil) -> Conversation {
        Conversation(title: title, model: model)
    }
}
