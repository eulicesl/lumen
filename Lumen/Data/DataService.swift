import SwiftData
import Foundation

actor DataService {
    static let shared = DataService()

    nonisolated let modelContainer: ModelContainer

    private init(inMemory: Bool = false) {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let schema = Schema.lumen
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: LumenMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static func forTesting() -> DataService {
        DataService(inMemory: true)
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = true
        return context
    }

    // MARK: - Conversation CRUD

    func createConversation(
        title: String = "New Conversation",
        systemPrompt: String? = nil
    ) throws -> UUID {
        let modelContext = makeContext()
        let conversation = ConversationSD(title: title, systemPrompt: systemPrompt)
        modelContext.insert(conversation)
        try modelContext.save()
        return conversation.id
    }

    func fetchConversation(id: UUID) throws -> Conversation? {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == id }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        return results.first?.toDomain()
    }

    func fetchAllConversations(sortedBy sort: SortOrder = .reverse) throws -> [Conversation] {
        let modelContext = makeContext()
        var descriptor = FetchDescriptor<ConversationSD>(
            sortBy: [SortDescriptor(\.updatedAt, order: sort)]
        )
        descriptor.fetchLimit = 500
        let results = try modelContext.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    func fetchPinnedConversations() throws -> [Conversation] {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.isPinned }
        let descriptor = FetchDescriptor<ConversationSD>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func updateConversationTitle(id: UUID, title: String) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == id }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else { return }
        conversation.title = title
        conversation.updatedAt = Date()
        try modelContext.save()
    }

    func updateConversationSystemPrompt(id: UUID, systemPrompt: String?) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == id }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else { return }
        conversation.systemPrompt = systemPrompt
        try modelContext.save()
    }

    func toggleConversationPin(id: UUID) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == id }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else { return }
        conversation.isPinned.toggle()
        try modelContext.save()
    }

    func deleteConversation(id: UUID) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == id }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(conversation)
        try modelContext.save()
    }

    func deleteAllConversations() throws {
        let modelContext = makeContext()
        let descriptor = FetchDescriptor<ConversationSD>()
        let all = try modelContext.fetch(descriptor)
        for conversation in all {
            modelContext.delete(conversation)
        }
        try modelContext.save()
    }

    // MARK: - Message CRUD

    func addMessage(_ message: ChatMessage, to conversationID: UUID) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == conversationID }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else {
            throw DataError.conversationNotFound(conversationID)
        }
        try addMessages([message], to: conversationID, using: modelContext, conversation: conversation)
    }

    func addMessages(_ messages: [ChatMessage], to conversationID: UUID) throws {
        guard !messages.isEmpty else { return }

        let modelContext = makeContext()
        let predicate = #Predicate<ConversationSD> { $0.id == conversationID }
        let descriptor = FetchDescriptor<ConversationSD>(predicate: predicate)
        guard let conversation = try modelContext.fetch(descriptor).first else {
            throw DataError.conversationNotFound(conversationID)
        }

        try addMessages(messages, to: conversationID, using: modelContext, conversation: conversation)
    }

    func updateMessage(id: UUID, content: String, isComplete: Bool = true, tokenCount: Int? = nil) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<MessageSD> { $0.id == id }
        let descriptor = FetchDescriptor<MessageSD>(predicate: predicate)
        guard let message = try modelContext.fetch(descriptor).first else { return }
        message.content = content
        message.isComplete = isComplete
        message.tokenCount = tokenCount
        try modelContext.save()
    }

    func deleteMessage(id: UUID) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<MessageSD> { $0.id == id }
        let descriptor = FetchDescriptor<MessageSD>(predicate: predicate)
        guard let message = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(message)
        try modelContext.save()
    }

    func fetchMessages(for conversationID: UUID) throws -> [ChatMessage] {
        let modelContext = makeContext()
        let predicate = #Predicate<MessageSD> { $0.conversation?.id == conversationID }
        let descriptor = FetchDescriptor<MessageSD>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    // MARK: - Model CRUD

    func saveModel(_ model: AIModel) throws {
        let modelContext = makeContext()
        let modelSD = AIModelSD.from(model)
        modelContext.insert(modelSD)
        try modelContext.save()
    }

    func fetchSavedModels() throws -> [AIModel] {
        let modelContext = makeContext()
        let descriptor = FetchDescriptor<AIModelSD>()
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func deleteModel(id: String) throws {
        let modelContext = makeContext()
        let predicate = #Predicate<AIModelSD> { $0.modelID == id }
        let descriptor = FetchDescriptor<AIModelSD>(predicate: predicate)
        guard let model = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(model)
        try modelContext.save()
    }

    private func addMessages(
        _ messages: [ChatMessage],
        to conversationID: UUID,
        using modelContext: ModelContext,
        conversation: ConversationSD
    ) throws {
        var previousCreatedAt: Date?
        for message in messages {
            let messageSD = MessageSD.from(message)
            if let previousCreatedAt,
               messageSD.createdAt <= previousCreatedAt {
                messageSD.createdAt = previousCreatedAt.addingTimeInterval(0.001)
            }
            messageSD.conversation = conversation
            modelContext.insert(messageSD)
            previousCreatedAt = messageSD.createdAt
        }
        conversation.updatedAt = Date()
        try modelContext.save()
    }
}

enum DataError: Error, LocalizedError {
    case conversationNotFound(UUID)
    case messageNotFound(UUID)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .conversationNotFound(let id):
            return "Conversation not found: \(id)"
        case .messageNotFound(let id):
            return "Message not found: \(id)"
        case .saveFailed(let underlying):
            return "Save failed: \(underlying.localizedDescription)"
        }
    }
}
