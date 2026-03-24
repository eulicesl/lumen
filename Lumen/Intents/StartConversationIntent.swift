import AppIntents
import Foundation

// MARK: - Start a new Lumen conversation

struct StartConversationIntent: AppIntent {
    static let title: LocalizedStringResource = "Start New Conversation"
    static let description = IntentDescription(
        "Opens Lumen and starts a new conversation.",
        categoryName: "Conversations"
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await ChatStore.shared.createNewConversation()
        AppStore.shared.selectedTab = .chat
        return .result()
    }
}

// MARK: - Open a specific conversation

struct OpenConversationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Conversation"
    static let description = IntentDescription(
        "Opens Lumen and navigates to a specific conversation.",
        categoryName: "Conversations"
    )
    static let openAppWhenRun = true

    @Parameter(title: "Conversation ID")
    var conversationID: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: conversationID) else { return .result() }
        let conversations = ChatStore.shared.conversations
        if let match = conversations.first(where: { $0.id == id }) {
            await ChatStore.shared.selectConversation(match)
            AppStore.shared.selectedTab = .chat
        }
        return .result()
    }
}
