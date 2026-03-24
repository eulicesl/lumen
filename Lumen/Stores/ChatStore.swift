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

    private let aiService = AIService.shared
    private let dataService = DataService.shared
    private var streamTask: Task<Void, Never>?

    private init() {}

    func loadConversations() async {
        do {
            let loaded = try await dataService.fetchAllConversations()
            conversations = loaded
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

    func send() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversation = selectedConversation else { return }
        guard let model = currentModel else { return }

        let text = inputText
        inputText = ""

        let userMessage = ChatMessage.userMessage(text)
        messages.append(userMessage)
        try? await dataService.addMessage(userMessage, to: conversation.id)

        let placeholder = ChatMessage.streamingPlaceholder(model: model)
        messages.append(placeholder)

        conversationState = .generating
        timeToFirstToken = nil
        let startTime = Date()
        var assistantContent = ""
        var assistantIndex = messages.count - 1

        streamTask = Task { @MainActor in
            let options = ChatOptions(systemPrompt: conversation.systemPrompt)
            let stream = await aiService.chat(messages: messages.dropLast(), model: model, options: options)

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

                let finalMessage = messages[assistantIndex]
                try? await dataService.addMessage(finalMessage, to: conversation.id)
                conversationState = .idle

                if conversations.first?.id == conversation.id {
                    try? await dataService.updateConversationTitle(
                        id: conversation.id,
                        title: conversation.title == "New Conversation" ? String(text.prefix(50)) : conversation.title
                    )
                    await loadConversations()
                }
            } catch is CancellationError {
                messages[assistantIndex].isComplete = true
                conversationState = .idle
            } catch {
                messages[assistantIndex] = ChatMessage.errorMessage(error.localizedDescription)
                conversationState = .error(error.localizedDescription)
            }
        }
    }

    func stopGeneration() {
        streamTask?.cancel()
        streamTask = nil
        conversationState = .idle
        if let lastIndex = messages.indices.last, messages[lastIndex].isStreaming {
            messages[lastIndex].isComplete = true
        }
    }

    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await dataService.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
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
