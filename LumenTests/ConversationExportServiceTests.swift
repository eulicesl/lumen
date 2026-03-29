import Foundation
import Testing
@testable import Lumen

@Suite("ConversationExportService")
struct ConversationExportServiceTests {
    private let service = ConversationExportService()

    @Test("JSON export includes versioned conversation envelope")
    func jsonExportEnvelope() throws {
        let conversation = sampleConversation()

        let data = try service.data(for: conversation, format: .json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(ConversationExportEnvelope.self, from: data)

        #expect(envelope.version == ConversationExportService.currentVersion)
        #expect(envelope.conversation.id == conversation.id)
        #expect(envelope.conversation.title == "Sprint Planning")
        #expect(envelope.conversation.model?.displayName == "Apple Intelligence")
        #expect(envelope.conversation.messages.count == 3)
        #expect(envelope.conversation.messages[1].content == "Need a concise plan.")
        #expect(envelope.conversation.messages[2].content == "Here is a short plan.")
    }

    @Test("Markdown export is readable and strips think blocks")
    func markdownExport() {
        let conversation = sampleConversation()

        let markdown = service.markdown(for: conversation)

        #expect(markdown.contains("# Sprint Planning"))
        #expect(markdown.contains("## System Prompt"))
        #expect(markdown.contains("## Messages"))
        #expect(markdown.contains("### You"))
        #expect(markdown.contains("### Assistant"))
        #expect(markdown.contains("Need a concise plan."))
        #expect(markdown.contains("Here is a short plan."))
        #expect(!markdown.contains("internal reasoning"))
    }

    @Test("Export filenames are sanitized and format-specific")
    func exportFilename() throws {
        let conversation = Conversation(title: "  Launch / Review: v1.0  ")

        let json = try service.exportFile(for: conversation, format: .json)
        let markdown = try service.exportFile(for: conversation, format: .markdown)

        #expect(json.filename == "launch-review-v1-0.json")
        #expect(markdown.filename == "launch-review-v1-0.md")
    }

    private func sampleConversation() -> Conversation {
        Conversation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Sprint Planning",
            createdAt: Date(timeIntervalSince1970: 1_710_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_710_000_600),
            isPinned: true,
            systemPrompt: "Be concise.",
            model: .appleFoundationModel,
            messages: [
                ChatMessage.systemMessage("Internal setup"),
                ChatMessage(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    role: .user,
                    content: "Need a concise plan.",
                    createdAt: Date(timeIntervalSince1970: 1_710_000_100)
                ),
                ChatMessage(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                    role: .assistant,
                    content: "<think>internal reasoning</think>\nHere is a short plan.",
                    createdAt: Date(timeIntervalSince1970: 1_710_000_200),
                    tokenCount: 42,
                    model: .appleFoundationModel
                )
            ]
        )
    }
}
