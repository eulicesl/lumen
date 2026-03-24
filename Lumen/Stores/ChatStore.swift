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
    var agentModeEnabled: Bool = false
    var agentEvents: [AgentEvent] = []

    private let aiService = AIService.shared
    private let dataService = DataService.shared
    private var streamTask: Task<Void, Never>?

    private init() {}

    // MARK: - Conversations

    func loadConversations() async {
        do {
            let loaded = try await dataService.fetchAllConversations()
            conversations = loaded
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
        selectedConversation = conversation
        do {
            let loaded = try await dataService.fetchMessages(for: conversation.id)
            messages = loaded
        } catch {
            messages = []
        }
    }

    func createNewConversation() async {
        do {
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
        let branchTitle = "Branch: \(String(conversation.title.prefix(35)))"

        do {
            let newID = try await dataService.createConversation(title: branchTitle)
            for msg in messagesToKeep {
                try await dataService.addMessage(msg, to: newID)
            }
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
        guard !text.isEmpty || !images.isEmpty else { return }
        guard let conversation = selectedConversation else { return }
        guard let model = currentModel else { return }

        inputText = ""
        pendingImageData = []
        agentEvents = []

        let userMessage = ChatMessage.userMessage(text, imageData: images.isEmpty ? nil : images)
        messages.append(userMessage)
        try? await dataService.addMessage(userMessage, to: conversation.id)

        let placeholder = ChatMessage.streamingPlaceholder(model: model)
        messages.append(placeholder)

        conversationState = .generating
        timeToFirstToken = nil
        let startTime = Date()
        let assistantIndex = messages.count - 1

        // Build options with memory injection
        let memoryContext = MemoryStore.shared.contextString
        let basePrompt = conversation.systemPrompt ?? ""
        let fullPrompt = [memoryContext, basePrompt].filter { !$0.isEmpty }.joined(separator: "\n\n")
        let options = ChatOptions(systemPrompt: fullPrompt.isEmpty ? nil : fullPrompt)
        let context = Array(messages.dropLast())

        if agentModeEnabled {
            streamTask = Task { @MainActor in
                await self.runAgentStream(
                    context: context,
                    model: model,
                    options: options,
                    assistantIndex: assistantIndex,
                    startTime: startTime,
                    conversation: conversation,
                    promptText: text
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
                    promptText: text
                )
            }
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
                assistantContent += text
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

        // Add a fresh streaming placeholder — do NOT re-append the user message
        let placeholder = ChatMessage.streamingPlaceholder(model: model)
        messages.append(placeholder)

        conversationState = .generating
        timeToFirstToken = nil
        let startTime = Date()
        let assistantIndex = messages.count - 1

        let memoryContext = MemoryStore.shared.contextString
        let basePrompt = conversation.systemPrompt ?? ""
        let fullPrompt = [memoryContext, basePrompt]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        let options = ChatOptions(systemPrompt: fullPrompt.isEmpty ? nil : fullPrompt)

        // Context is everything except the new placeholder
        let context = Array(messages.dropLast())
        let promptText = context.last(where: { $0.isUser })?.content ?? ""

        if agentModeEnabled {
            streamTask = Task { @MainActor in
                await self.runAgentStream(
                    context: context, model: model, options: options,
                    assistantIndex: assistantIndex, startTime: startTime,
                    conversation: conversation, promptText: promptText
                )
            }
        } else {
            streamTask = Task { @MainActor in
                await self.runDirectStream(
                    context: context, model: model, options: options,
                    assistantIndex: assistantIndex, startTime: startTime,
                    conversation: conversation, promptText: promptText
                )
            }
        }
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
            Task.detached(priority: .background) {
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

    func togglePin(_ conversation: Conversation) async {
        do {
            try await dataService.toggleConversationPin(id: conversation.id)
            await loadConversations()
        } catch {}
    }
}
