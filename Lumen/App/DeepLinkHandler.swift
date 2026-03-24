import Foundation
import CoreSpotlight

// MARK: - Deep link URL scheme: lumen://
//
// Supported paths:
//   lumen://conversation/<UUID>   — open a specific conversation
//   lumen://new                   — start a new conversation
//   lumen://ask?q=<text>          — open a new conversation with pre-filled text
//
// Also handles NSUserActivity from Spotlight (CSSearchableItemActionType).

@MainActor
final class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    private init() {}

    func handle(url: URL) async {
        guard url.scheme?.lowercased() == "lumen" else { return }
        let host = url.host ?? ""

        switch host {
        case "conversation":
            if let uuidString = url.pathComponents.dropFirst().first,
               let id = UUID(uuidString: uuidString) {
                await openConversation(id: id)
            }

        case "new":
            await ChatStore.shared.createNewConversation()
            AppStore.shared.selectedTab = .chat

        case "ask":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let query = components?.queryItems?.first(where: { $0.name == "q" })?.value,
               !query.isEmpty {
                await ChatStore.shared.createNewConversation()
                ChatStore.shared.inputText = query
                AppStore.shared.selectedTab = .chat
            }

        default:
            AppStore.shared.selectedTab = .chat
        }
    }

    func handle(userActivity: NSUserActivity) async {
        if userActivity.activityType == CSSearchableItemActionType,
           let id = SpotlightService.conversationID(from: userActivity) {
            await openConversation(id: id)
        }
    }

    private func openConversation(id: UUID) async {
        let store = ChatStore.shared
        if let match = store.conversations.first(where: { $0.id == id }) {
            await store.selectConversation(match)
        } else {
            await store.loadConversations()
            if let match = store.conversations.first(where: { $0.id == id }) {
                await store.selectConversation(match)
            }
        }
        AppStore.shared.selectedTab = .chat
    }
}
