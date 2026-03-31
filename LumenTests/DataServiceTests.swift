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

@Suite("DocumentPromptComposer")
struct DocumentPromptComposerTests {

    @Test("Compose request with imported documents")
    func composeRequestWithDocuments() {
        let document = ImportedDocument(
            fileName: "brief.txt",
            extractedText: "Quarterly roadmap and milestones.",
            contentTypeIdentifier: "public.plain-text"
        )

        let composed = DocumentPromptComposer.compose(
            userText: "Summarize this",
            documents: [document]
        )

        #expect(composed.contains("Summarize this"))
        #expect(composed.contains("<<LUMEN::DOCUMENT::brief.txt>>"))
        #expect(composed.contains("Quarterly roadmap and milestones."))
    }

    @Test("Compose document-only request adds fallback instruction")
    func composeDocumentOnlyRequest() {
        let document = ImportedDocument(
            fileName: "notes.md",
            extractedText: "Standup notes",
            contentTypeIdentifier: "net.daringfireball.markdown"
        )

        let composed = DocumentPromptComposer.compose(userText: "", documents: [document])

        #expect(composed.contains("Please use the imported document context below"))
        #expect(composed.contains("<<LUMEN::DOCUMENT::notes.md>>"))
    }

    @Test("Normalize extracted text trims noise and truncates")
    func normalizeExtractedText() {
        let source = String(repeating: "Line one with additional detail. ", count: 8)
        let normalized = DocumentPromptComposer.normalizeExtractedText(source, maxCharacters: 80)

        #expect(normalized.contains("Line one"))
        #expect(normalized.contains("Document truncated"))
        #expect(!normalized.contains("\r"))
    }

    @Test("Document-aware display text hides raw imported content")
    func documentAwareDisplayText() {
        let content = """
        Summarize the attached file.

        <<LUMEN::DOCUMENT::brief.txt>>
        Internal project detail that should not flood the transcript.
        <<LUMEN::END_DOCUMENT>>
        """

        let display = content.documentAwareDisplayText

        #expect(display.contains("Summarize the attached file."))
        #expect(display.contains("Attached document: brief.txt"))
        #expect(!display.contains("Internal project detail"))
    }

    @Test("Normalize extracted text preserves indentation for code-like content")
    func normalizeExtractedTextPreservesIndentation() {
        let source = """
        func greet() {
            print("hello")
        }
        """

        let normalized = DocumentPromptComposer.normalizeExtractedText(source)
        #expect(normalized.contains("    print(\"hello\")"))
    }

    @Test("Title seed falls back to document name")
    func titleSeedFallsBackToDocumentName() {
        let document = ImportedDocument(
            fileName: "research.pdf",
            extractedText: "Content",
            contentTypeIdentifier: "com.adobe.pdf"
        )

        let titleSeed = DocumentPromptComposer.titleSeed(userText: "", documents: [document])
        #expect(titleSeed == "Discuss research.pdf")
    }
}
