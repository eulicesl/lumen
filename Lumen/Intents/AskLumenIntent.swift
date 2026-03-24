import AppIntents
import Foundation

// MARK: - Ask Lumen a question (Siri + Shortcuts)

struct AskLumenIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Lumen"
    static let description = IntentDescription(
        "Sends a question or prompt to Lumen AI and opens the conversation.",
        categoryName: "AI"
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Question",
        description: "The prompt or question to send to Lumen.",
        requestValueDialog: IntentDialog("What would you like to ask Lumen?")
    )
    var query: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = ChatStore.shared
        AppStore.shared.selectedTab = .chat

        if store.selectedConversation == nil || store.messages.count > 0 {
            await store.createNewConversation()
        }

        guard store.currentModel != nil else {
            return .result()
        }

        store.inputText = query
        await store.send()

        return .result()
    }
}

// MARK: - Summarize last conversation

struct SummarizeConversationIntent: AppIntent {
    static let title: LocalizedStringResource = "Summarize Last Conversation"
    static let description = IntentDescription(
        "Asks Lumen to summarize the most recent conversation.",
        categoryName: "AI"
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = ChatStore.shared
        AppStore.shared.selectedTab = .chat

        guard let conversation = store.conversations.first else {
            return .result()
        }
        await store.selectConversation(conversation)

        guard store.currentModel != nil, !store.messages.isEmpty else {
            return .result()
        }

        store.inputText = "Please give me a brief summary of our conversation so far."
        await store.send()

        return .result()
    }
}
