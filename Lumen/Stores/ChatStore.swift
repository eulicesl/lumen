import Foundation
import Observation

@Observable
@MainActor
final class ChatStore {
    static let shared = ChatStore()

    var conversations: [Conversation] = []
    var selectedConversation: Conversation?
    var messages: [ChatMessage] = []
    var conversationState: ConversationState = .idle
    var inputText: String = ""
    var currentModel: AIModel?
    var timeToFirstToken: TimeInterval?
    var pendingImageData: [Data] = []
    var pendingDocuments: [ImportedDocument] = []
    var agentModeEnabled: Bool = false
    var agentEvents: [AgentEvent] = []
    var editingMessageID: UUID?
    var focusedMessageID: UUID?

    private let aiService = AIService.shared
    private let dataService = DataService.shared
    private var streamTask: Task<Void, Never>?

    private init() {}

    // MARK: - Conversations

    func loadConversations() async {
        do {
            let loaded = try await dataService.fetchAllConversations()
            conversations = loaded
            if let currentID = selectedConversation?.id {
                selectedConversation = loaded.first(where: { $0.id == currentID })
            }
            Task.detached(priority: .background) {
                await SpotlightService.shared.indexConversations(loaded)
                let widgets = loaded.prefix(5).map { conv in
                    WidgetConversation(
                        id: conv.id.uuidString,
                        title: conv.title,
                        preview: conv.preview,
                        updatedAt: conv.updatedAt
                    )
                }
                WidgetSharedStore.save(Array(widgets))
            }
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Failed to Load",
                message: error.localizedDescription
            )
        }
    }

    func selectConversation(_ conversation: Conversation) async {
        await selectConversation(conversation, focusingOn: nil)
    }

    func selectConversation(
        _ conversation: Conversation,
        focusingOn messageID: UUID?
    ) async {
        self.editingMessageID = nil
        selectedConversation = conversation
        focusedMessageID = messageID
        pendingDocuments = []
        do {
            let loaded = try await dataService.fetchMessages(for: conversation.id)
            messages = loaded
            if let messageID, !loaded.contains(where: { $0.id == messageID }) {
                focusedMessageID = nil
            }
        } catch {
            messages = []
            focusedMessageID = nil
        }
    }

    func restoreSelectedConversation(id: UUID?) async {
        guard !conversations.isEmpty else { return }

        if let id,
           let conversation = conversations.first(where: { $0.id == id }) {
            if selectedConversation?.id != id {
                await selectConversation(conversation)
            }
            return
        }

        if selectedConversation == nil, let firstConversation = conversations.first {
            await selectConversation(firstConversation)
        }
    }

    // MARK: - Message editing

    var isEditingMessage: Bool { editingMessageID != nil }

    var editingMessagePreview: String? {
        guard let editingMessageID else { return nil }
        return messages
            .first(where: { $0.id == editingMessageID })?
            .content
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func beginEditing(_ message: ChatMessage) {
        guard message.isUser, !message.hasImages else { return }
        editingMessageID = message.id
        inputText = message.content
        pendingImageData = []
    }

    func cancelEditing() {
        self.editingMessageID = nil
        inputText = ""
        pendingImageData = []
    }

    func createNewConversation() async {
        pendingDocuments = []
        do {
            editingMessageID = nil
            let id = try await dataService.createConversation()
            let new = try await dataService.fetchConversation(id: id)
            if let conv = new {
                conversations.insert(conv, at: 0)
                await selectConversation(conv)
            }
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Failed to Create",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Conversation branching

    func branchFrom(message: ChatMessage) async {
        guard let conversation = selectedConversation else { return }
        guard let idx = messages.firstIndex(of: message) else { return }

        let messagesToKeep = Array(messages[...idx])

        do {
            let newID = try await dataService.createConversation(
                title: branchTitle(for: conversation),
                systemPrompt: conversation.systemPrompt
            )
            try await dataService.addMessages(messagesToKeep, to: newID)
            guard let newConv = try await dataService.fetchConversation(id: newID) else { return }
            conversations.insert(newConv, at: 0)
            await selectConversation(newConv)
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Branch Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Send message

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let images = pendingImageData
        let documents = pendingDocuments
        guard !text.isEmpty || !images.isEmpty || !documents.isEmpty else { return }
        guard let conversation = selectedConversation else { return }
        guard let model = currentModel else { return }

        if let editingMessageID {
            await sendEditedMessage(
                editingMessageID: editingMessageID,
                editedText: text,
                conversation: conversation,
                model: model
            )
            return
        }

        let composedText = DocumentPromptComposer.compose(userText: text, documents: documents)
        let titleSeed = DocumentPromptComposer.titleSeed(userText: text, documents: documents)

        inputText = ""
        pendingImageData = []
        pendingDocuments = []
        agentEvents = []
        focusedMessageID = nil

        let userMessage = ChatMessage.userMessage(
            composedText,
            imageData: images.isEmpty ? nil : images
        )
        messages.append(userMessage)
        try? await dataService.addMessage(userMessage, to: conversation.id)
        beginStreamingReply(
            model: model,
            conversation: conversation,
            promptText: titleSeed
        )
    }

    private func sendEditedMessage(
        editingMessageID: UUID,
        editedText: String,
        conversation: Conversation,
        model: AIModel
    ) async {
        guard let plan = ConversationEditEngine.plan(
            messages: messages,
            editingMessageID: editingMessageID,
            replacementText: editedText
        ) else {
            AppStore.shared.activeAlert = AppAlert(
                title: "Unable to Edit Message",
                message: "Only completed text user messages can be edited from history."
            )
            return
        }

        inputText = ""
        pendingImageData = []
        agentEvents = []
        self.editingMessageID = nil

        do {
            let newConversationID = try await dataService.createConversation(
                title: branchTitle(for: conversation),
                systemPrompt: conversation.systemPrompt
            )
            try await dataService.addMessages(
                plan.preservedMessages + [plan.editedMessage],
                to: newConversationID
            )

            guard let branchedConversation = try await dataService.fetchConversation(id: newConversationID) else {
                throw DataError.conversationNotFound(newConversationID)
            }

            conversations.insert(branchedConversation, at: 0)
            selectedConversation = branchedConversation
            messages = plan.contextMessages
            pendingDocuments = []
            focusedMessageID = nil

            HapticEngine.impact(.medium)
            beginStreamingReply(
                model: model,
                conversation: branchedConversation,
                promptText: editedText
            )
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Edit Failed",
                message: error.localizedDescription
            )
            conversationState = .idle
        }
    }

    // MARK: - Direct streaming

    private func runDirectStream(
        context: [ChatMessage],
        model: AIModel,
        options: ChatOptions,
        assistantIndex: Int,
        startTime: Date,
        conversation: Conversation,
        promptText: String
    ) async {
        var assistantContent = ""
        let stream = await aiService.chat(messages: context, model: model, options: options)

        do {
            for try await token in stream {
                if Task.isCancelled { break }
                if timeToFirstToken == nil {
                    timeToFirstToken = Date().timeIntervalSince(startTime)
                }
                assistantContent += token.text
                messages[assistantIndex].content = assistantContent
                if token.isComplete {
                    messages[assistantIndex].isComplete = true
                    messages[assistantIndex].tokenCount = token.tokenCount
                }
            }
            await finalize(assistantIndex: assistantIndex, conversation: conversation, promptText: promptText)
        } catch is CancellationError {
            messages[assistantIndex].isComplete = true
            conversationState = .idle
        } catch {
            messages[assistantIndex] = ChatMessage.errorMessage(error.localizedDescription)
            conversationState = .error(error.localizedDescription)
        }
    }

    // MARK: - Agent streaming

    private func runAgentStream(
        context: [ChatMessage],
        model: AIModel,
        options: ChatOptions,
        assistantIndex: Int,
        startTime: Date,
        conversation: Conversation,
        promptText: String
    ) async {
        var assistantContent = ""
        let agentStream = await AgentService.shared.run(
            messages: context,
            model: model,
            options: options
        )

        for await event in agentStream {
            if Task.isCancelled { break }
            switch event {
            case .token(let text):
                if timeToFirstToken == nil {
                    timeToFirstToken = Date().timeIntervalSince(startTime)
                }
                assistantContent = text
                messages[assistantIndex].content = assistantContent
            case .complete(let tokenCount):
                messages[assistantIndex].isComplete = true
                messages[assistantIndex].tokenCount = tokenCount
            case .error(let desc):
                messages[assistantIndex] = ChatMessage.errorMessage(desc)
                conversationState = .error(desc)
                return
            case .toolCall, .toolResult:
                agentEvents.append(event)
            }
        }

        if !Task.isCancelled {
            await finalize(assistantIndex: assistantIndex, conversation: conversation, promptText: promptText)
        } else {
            messages[assistantIndex].isComplete = true
            conversationState = .idle
        }
    }

    // MARK: - Post-stream cleanup

    private func finalize(assistantIndex: Int, conversation: Conversation, promptText: String) async {
        let finalMessage = messages[assistantIndex]
        try? await dataService.addMessage(finalMessage, to: conversation.id)
        conversationState = .idle
        HapticEngine.notification(.success)
        ReviewRequestManager.shared.recordSuccessfulResponse()

        if conversation.title == "New Conversation" && !promptText.isEmpty {
            try? await dataService.updateConversationTitle(
                id: conversation.id,
                title: String(promptText.prefix(50))
            )
            await loadConversations()
        }
    }

    // MARK: - Stop

    func stopGeneration() {
        streamTask?.cancel()
        streamTask = nil
        conversationState = .idle
        if let lastIndex = messages.indices.last, messages[lastIndex].isStreaming {
            messages[lastIndex].isComplete = true
        }
    }

    // MARK: - Regenerate

    var canRegenerate: Bool {
        conversationState == .idle &&
        messages.last?.isAssistant == true &&
        messages.last?.isComplete == true
    }

    var canRetryLastResponse: Bool {
        messages.last?.isError == true &&
        selectedConversation != nil &&
        currentModel != nil &&
        !conversationState.isGenerating
    }

    func regenerate() async {
        guard canRegenerate else { return }
        guard let lastAssistant = messages.last, lastAssistant.isAssistant else { return }
        guard let conversation = selectedConversation else { return }
        guard let model = currentModel else { return }

        // Remove the last assistant response from memory and persistence
        try? await dataService.deleteMessage(id: lastAssistant.id)
        messages.removeLast()

        HapticEngine.impact(.medium)
        agentEvents = []
        let promptText = messages.last(where: { $0.isUser })?.content ?? ""
        beginStreamingReply(
            model: model,
            conversation: conversation,
            promptText: promptText
        )
    }

    func retryLastResponse() async {
        guard canRetryLastResponse else { return }
        guard let conversation = selectedConversation else { return }
        guard let model = currentModel else { return }

        messages.removeLast()
        agentEvents = []
        HapticEngine.impact(.medium)
        let promptText = messages.last(where: { $0.isUser })?.content ?? ""
        beginStreamingReply(
            model: model,
            conversation: conversation,
            promptText: promptText
        )
    }

    // MARK: - Export / Share

    var exportText: String {
        guard let conv = selectedConversation else { return "" }
        let header = "Conversation: \(conv.title)\n\(String(repeating: "─", count: 40))\n\n"
        let body = messages
            .filter { $0.isUser || $0.isAssistant }
            .filter { $0.isComplete && !$0.isError }
            .map { msg -> String in
                let role = msg.isUser ? "You" : "Lumen"
                let content = msg.isAssistant
                    ? msg.content.stripThinkBlocks()
                    : msg.content
                return "\(role):\n\(content)"
            }
            .joined(separator: "\n\n")
        return header + body
    }

    // MARK: - Delete

    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await dataService.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
            Task { @MainActor in
                await SpotlightService.shared.deleteConversation(id: conversation.id)
                let widgets = ChatStore.shared.conversations.prefix(5).map { conv in
                    WidgetConversation(
                        id: conv.id.uuidString,
                        title: conv.title,
                        preview: conv.preview,
                        updatedAt: conv.updatedAt
                    )
                }
                WidgetSharedStore.save(Array(widgets))
            }
            if selectedConversation?.id == conversation.id {
                selectedConversation = conversations.first
                if let first = selectedConversation {
                    await selectConversation(first)
                } else {
                    messages = []
                }
            }
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Failed to Delete",
                message: error.localizedDescription
            )
        }
    }

    func deleteAllConversations() async {
        do {
            try await dataService.deleteAllConversations()
            conversations = []
            selectedConversation = nil
            messages = []
            editingMessageID = nil
            focusedMessageID = nil
            pendingDocuments = []
            Task.detached(priority: .background) {
                await SpotlightService.shared.deleteAll()
                WidgetSharedStore.save([])
            }
            await createNewConversation()
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Failed to Reset",
                message: error.localizedDescription
            )
        }
    }

    func renameConversation(_ conversation: Conversation, to name: String) async {
        do {
            try await dataService.updateConversationTitle(id: conversation.id, title: name)
            await loadConversations()
        } catch {}
    }

    func setSystemPrompt(_ prompt: String?, for conversation: Conversation) async {
        let normalized = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value: String? = (normalized?.isEmpty ?? true) ? nil : normalized
        do {
            try await dataService.updateConversationSystemPrompt(
                id: conversation.id,
                systemPrompt: value
            )
            if selectedConversation?.id == conversation.id {
                selectedConversation?.systemPrompt = value
            }
            await loadConversations()
        } catch {}
    }

    func togglePin(_ conversation: Conversation) async {
        do {
            try await dataService.toggleConversationPin(id: conversation.id)
            await loadConversations()
        } catch {}
    }

    private func branchTitle(for conversation: Conversation) -> String {
        "Branch: \(String(conversation.title.prefix(35)))"
    }

    private func chatOptions(for conversation: Conversation, promptText: String) -> ChatOptions {
        let memoryContext = MemoryStore.shared.contextString(for: promptText)
        let basePrompt = conversation.systemPrompt ?? ""
        let fullPrompt = [memoryContext, basePrompt]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        return ChatOptions(systemPrompt: fullPrompt.isEmpty ? nil : fullPrompt)
    }

    private func beginStreamingReply(
        model: AIModel,
        conversation: Conversation,
        promptText: String
    ) {
        let context = messages
        restartStream(
            context: context,
            model: model,
            conversation: conversation,
            promptText: promptText
        )
    }

    private func restartStream(
        context: [ChatMessage],
        model: AIModel,
        conversation: Conversation,
        promptText: String
    ) {
        let placeholder = ChatMessage.streamingPlaceholder(model: model)
        messages.append(placeholder)

        conversationState = .generating
        timeToFirstToken = nil
        let startTime = Date()
        let assistantIndex = messages.count - 1

        startStream(
            context: context,
            model: model,
            options: chatOptions(for: conversation, promptText: promptText),
            assistantIndex: assistantIndex,
            startTime: startTime,
            conversation: conversation,
            promptText: promptText
        )
    }

    private func startStream(
        context: [ChatMessage],
        model: AIModel,
        options: ChatOptions,
        assistantIndex: Int,
        startTime: Date,
        conversation: Conversation,
        promptText: String
    ) {
        if agentModeEnabled {
            streamTask = Task { @MainActor in
                await self.runAgentStream(
                    context: context,
                    model: model,
                    options: options,
                    assistantIndex: assistantIndex,
                    startTime: startTime,
                    conversation: conversation,
                    promptText: promptText
                )
            }
        } else {
            streamTask = Task { @MainActor in
                await self.runDirectStream(
                    context: context,
                    model: model,
                    options: options,
                    assistantIndex: assistantIndex,
                    startTime: startTime,
                    conversation: conversation,
                    promptText: promptText
                )
            }
        }
    }
}

struct ConversationEditPlan: Equatable {
    let preservedMessages: [ChatMessage]
    let editedMessage: ChatMessage

    var contextMessages: [ChatMessage] {
        preservedMessages + [editedMessage]
    }
}

enum ConversationEditEngine {
    static func plan(
        messages: [ChatMessage],
        editingMessageID: UUID,
        replacementText: String
    ) -> ConversationEditPlan? {
        guard let index = messages.firstIndex(where: { $0.id == editingMessageID }) else {
            return nil
        }

        let originalMessage = messages[index]
        guard originalMessage.isUser, originalMessage.isComplete, !originalMessage.isError, !originalMessage.hasImages else {
            return nil
        }

        let preservedMessages = Array(messages[..<index])
        let editedMessage = ChatMessage.userMessage(replacementText)

        return ConversationEditPlan(
            preservedMessages: preservedMessages,
            editedMessage: editedMessage
        )
    }
}
