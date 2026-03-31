import Foundation
import Testing
@testable import Lumen

@Suite("DataService")
struct DataServiceTests {

    @Test("Create and fetch a conversation")
    func createAndFetchConversation() async throws {
        let service = DataService.forTesting()
        let id = try await service.createConversation(title: "Test Conversation")
        let fetched = try await service.fetchConversation(id: id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Test Conversation")
        #expect(fetched?.messages.isEmpty == true)
        #expect(fetched?.isPinned == false)
    }

    @Test("Fetch all conversations returns created ones")
    func fetchAllConversations() async throws {
        let service = DataService.forTesting()
        let id1 = try await service.createConversation(title: "Conversation A")
        let id2 = try await service.createConversation(title: "Conversation B")
        let all = try await service.fetchAllConversations()
        let ids = all.map { $0.id }
        #expect(ids.contains(id1))
        #expect(ids.contains(id2))
        #expect(all.count >= 2)
    }

    @Test("Update conversation title")
    func updateConversationTitle() async throws {
        let service = DataService.forTesting()
        let id = try await service.createConversation(title: "Old Title")
        try await service.updateConversationTitle(id: id, title: "New Title")
        let fetched = try await service.fetchConversation(id: id)
        #expect(fetched?.title == "New Title")
    }

    @Test("Delete a conversation")
    func deleteConversation() async throws {
        let service = DataService.forTesting()
        let id = try await service.createConversation(title: "To Delete")
        try await service.deleteConversation(id: id)
        let fetched = try await service.fetchConversation(id: id)
        #expect(fetched == nil)
    }

    @Test("Add and fetch messages in a conversation")
    func addAndFetchMessages() async throws {
        let service = DataService.forTesting()
        let conversationID = try await service.createConversation(title: "Message Test")
        let userMsg = ChatMessage.userMessage("Hello, AI!")
        let assistantMsg = ChatMessage.assistantMessage("Hello! How can I help?")
        try await service.addMessage(userMsg, to: conversationID)
        try await service.addMessage(assistantMsg, to: conversationID)
        let messages = try await service.fetchMessages(for: conversationID)
        #expect(messages.count == 2)
        #expect(messages[0].content == "Hello, AI!")
        #expect(messages[0].role == .user)
        #expect(messages[1].content == "Hello! How can I help?")
        #expect(messages[1].role == .assistant)
    }

    @Test("Delete a specific message")
    func deleteMessage() async throws {
        let service = DataService.forTesting()
        let conversationID = try await service.createConversation(title: "Delete Message Test")
        let msg = ChatMessage.userMessage("Delete me")
        try await service.addMessage(msg, to: conversationID)
        try await service.deleteMessage(id: msg.id)
        let messages = try await service.fetchMessages(for: conversationID)
        #expect(messages.isEmpty)
    }

    @Test("Batch add messages preserves order")
    func batchAddMessages() async throws {
        let service = DataService.forTesting()
        let conversationID = try await service.createConversation(title: "Batch Message Test")
        let messagesToInsert = [
            ChatMessage.userMessage("First"),
            ChatMessage.assistantMessage("Second"),
            ChatMessage.userMessage("Third")
        ]

        try await service.addMessages(messagesToInsert, to: conversationID)

        let fetched = try await service.fetchMessages(for: conversationID)
        #expect(fetched.map(\.content) == ["First", "Second", "Third"])
    }

    @Test("Toggle conversation pin status")
    func toggleConversationPin() async throws {
        let service = DataService.forTesting()
        let id = try await service.createConversation(title: "Pin Test")
        let beforePin = try await service.fetchConversation(id: id)
        #expect(beforePin?.isPinned == false)
        try await service.toggleConversationPin(id: id)
        let afterPin = try await service.fetchConversation(id: id)
        #expect(afterPin?.isPinned == true)
        try await service.toggleConversationPin(id: id)
        let afterUnpin = try await service.fetchConversation(id: id)
        #expect(afterUnpin?.isPinned == false)
    }

    @Test("Fetching conversation with system prompt")
    func conversationWithSystemPrompt() async throws {
        let service = DataService.forTesting()
        let prompt = "You are a helpful coding assistant."
        let id = try await service.createConversation(title: "Coding Session", systemPrompt: prompt)
        let fetched = try await service.fetchConversation(id: id)
        #expect(fetched?.systemPrompt == prompt)
        #expect(fetched?.hasSystemPrompt == true)
    }

    @Test("Fetch non-existent conversation returns nil")
    func fetchNonExistentConversation() async throws {
        let service = DataService.forTesting()
        let randomID = UUID()
        let fetched = try await service.fetchConversation(id: randomID)
        #expect(fetched == nil)
    }
}

@Suite("MockAIProvider")
struct MockAIProviderTests {

    @Test("Mock provider reports availability correctly")
    func availability() async {
        let provider = MockAIProvider()
        let available = await provider.checkAvailability()
        #expect(available == true)

        await provider.setShouldBeAvailable(false)
        let unavailable = await provider.checkAvailability()
        #expect(unavailable == false)
    }

    @Test("Mock provider lists stubbed models")
    func listModels() async throws {
        let provider = MockAIProvider()
        let models = try await provider.listModels()
        #expect(models.count == 2)
        #expect(models[0].id == "mock.model-a")
        #expect(models[1].supportsImages == true)
    }

    @Test("Mock provider streams response tokens")
    func chatStreaming() async throws {
        let provider = MockAIProvider()
        let model = AIModel(id: "mock.a", name: "mock-a", providerType: .ollama)
        let messages = [ChatMessage.userMessage("Hello")]
        var tokens: [ChatToken] = []
        let stream = await provider.chat(messages: messages, model: model, options: .defaults)
        for try await token in stream {
            tokens.append(token)
        }
        #expect(!tokens.isEmpty)
        #expect(tokens.last?.isComplete == true)
        let finalText = tokens.last?.text ?? ""
        #expect(finalText.contains("mock response"))
    }

    @Test("Mock provider throws error when configured to")
    func chatThrowsError() async throws {
        let provider = MockAIProvider()
        await provider.setShouldThrowError(true)
        let model = AIModel(id: "mock.a", name: "mock-a", providerType: .ollama)
        let messages = [ChatMessage.userMessage("Hello")]
        let stream = await provider.chat(messages: messages, model: model, options: .defaults)
        do {
            for try await _ in stream {}
            Issue.record("Expected error was not thrown")
        } catch {
            #expect(error is AIProviderError)
        }
    }
}

extension MockAIProvider {
    func setShouldBeAvailable(_ value: Bool) {
        self.shouldBeAvailable = value
    }
    func setShouldThrowError(_ value: Bool) {
        self.shouldThrowError = value
    }
}

@Suite("ConversationSearchEngine")
struct ConversationSearchEngineTests {

    @Test("Search returns message-level matches from history")
    func messageLevelMatches() {
        let matchingMessage = ChatMessage.userMessage(
            "We should ship the neutron launch checklist today."
        )
        let conversation = Conversation(
            title: "Launch Prep",
            messages: [
                ChatMessage.assistantMessage("Status noted."),
                matchingMessage
            ]
        )

        let results = ConversationSearchEngine.search("neutron", in: [conversation])

        #expect(results.contains(where: {
            $0.section == .messages && $0.matchedMessageID == matchingMessage.id
        }))
    }

    @Test("Search ignores system messages")
    func ignoresSystemMessages() {
        let conversation = Conversation(
            title: "Hidden Prompt",
            messages: [
                ChatMessage.systemMessage("internal neutron guidance"),
                ChatMessage.assistantMessage("Visible reply")
            ]
        )

        let results = ConversationSearchEngine.search("neutron", in: [conversation])

        #expect(results.isEmpty)
    }

    @Test("Search includes a conversation hit and message hit when both match")
    func titleAndMessageMatchesCanCoexist() {
        let matchingMessage = ChatMessage.assistantMessage(
            "Orbit planning is on track."
        )
        let conversation = Conversation(
            title: "Orbit Review",
            messages: [matchingMessage]
        )

        let results = ConversationSearchEngine.search("orbit", in: [conversation])

        #expect(results.contains(where: {
            $0.section == .conversations && $0.id == conversation.id
        }))
        #expect(results.contains(where: {
            $0.section == .messages && $0.matchedMessageID == matchingMessage.id
        }))
    }

    @Test("Search excerpts center the matched text")
    func excerptsHighlightTheMatchContext() throws {
        let message = ChatMessage.assistantMessage(
            "Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda."
        )
        let conversation = Conversation(
            title: "Greek",
            messages: [message]
        )

        let results = ConversationSearchEngine.search("theta", in: [conversation])
        let excerpt = try #require(results.first?.subtitle)

        #expect(excerpt.contains("theta"))
        #expect(!excerpt.hasPrefix("Alpha beta gamma"))
    }
}

@Suite("ConversationEditEngine")
struct ConversationEditEngineTests {

    @Test("Edit plan preserves only messages before the edited turn")
    func preservesHistoryBeforeEditPoint() throws {
        let firstUser = ChatMessage.userMessage("Original question")
        let firstAssistant = ChatMessage.assistantMessage("Original answer")
        let editedUser = ChatMessage.userMessage("Needs revision")
        let laterAssistant = ChatMessage.assistantMessage("Later answer")

        let plan = try #require(
            ConversationEditEngine.plan(
                messages: [firstUser, firstAssistant, editedUser, laterAssistant],
                editingMessageID: editedUser.id,
                replacementText: "Revised question"
            )
        )

        #expect(plan.preservedMessages.map(\.id) == [firstUser.id, firstAssistant.id])
        #expect(plan.editedMessage.content == "Revised question")
        #expect(plan.contextMessages.count == 3)
    }

    @Test("Edit plan rejects assistant messages")
    func rejectsAssistantMessages() {
        let assistant = ChatMessage.assistantMessage("Cannot edit assistant")

        let plan = ConversationEditEngine.plan(
            messages: [assistant],
            editingMessageID: assistant.id,
            replacementText: "Replacement"
        )

        #expect(plan == nil)
    }

    @Test("Edit plan rejects user messages with images")
    func rejectsImageMessages() {
        let userWithImage = ChatMessage.userMessage(
            "Look at this",
            imageData: [Data([0x01])]
        )

        let plan = ConversationEditEngine.plan(
            messages: [userWithImage],
            editingMessageID: userWithImage.id,
            replacementText: "Replacement"
        )

        #expect(plan == nil)
    }
}
