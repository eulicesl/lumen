import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

actor SpotlightService {
    static let shared = SpotlightService()

    private let domainID = "ai.lumen.conversations"
    private let index = CSSearchableIndex.default()

    private init() {}

    // MARK: - Index a single conversation

    func indexConversation(_ conversation: Conversation) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
        attributeSet.title = conversation.title
        attributeSet.contentDescription = conversation.preview.isEmpty
            ? "Conversation in Lumen"
            : conversation.preview
        attributeSet.displayName = conversation.title
        attributeSet.keywords = ["lumen", "ai", "chat", "conversation"]
        attributeSet.contentCreationDate = conversation.createdAt
        attributeSet.contentModificationDate = conversation.updatedAt
        attributeSet.thumbnailData = nil

        let item = CSSearchableItem(
            uniqueIdentifier: "ai.lumen.conversation.\(conversation.id.uuidString)",
            domainIdentifier: domainID,
            attributeSet: attributeSet
        )
        item.expirationDate = Date().addingTimeInterval(60 * 60 * 24 * 365)

        index.indexSearchableItems([item]) { _ in }
    }

    // MARK: - Index multiple conversations

    func indexConversations(_ conversations: [Conversation]) {
        let items = conversations.map { conversation -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
            attributeSet.title = conversation.title
            attributeSet.contentDescription = conversation.preview.isEmpty
                ? "Conversation in Lumen"
                : conversation.preview
            attributeSet.keywords = ["lumen", "ai", "chat", "conversation"]
            attributeSet.contentCreationDate = conversation.createdAt
            attributeSet.contentModificationDate = conversation.updatedAt

            let item = CSSearchableItem(
                uniqueIdentifier: "ai.lumen.conversation.\(conversation.id.uuidString)",
                domainIdentifier: domainID,
                attributeSet: attributeSet
            )
            item.expirationDate = Date().addingTimeInterval(60 * 60 * 24 * 365)
            return item
        }

        guard !items.isEmpty else { return }
        index.indexSearchableItems(items) { _ in }
    }

    // MARK: - Remove conversation

    func deleteConversation(id: UUID) {
        let identifier = "ai.lumen.conversation.\(id.uuidString)"
        index.deleteSearchableItems(withIdentifiers: [identifier]) { _ in }
    }

    // MARK: - Remove all Lumen conversations

    func deleteAll() {
        index.deleteSearchableItems(withDomainIdentifiers: [domainID]) { _ in }
    }

    // MARK: - Parse incoming Spotlight deeplink

    static func conversationID(from userActivity: NSUserActivity) -> UUID? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix("ai.lumen.conversation.") else { return nil }

        let uuidString = String(identifier.dropFirst("ai.lumen.conversation.".count))
        return UUID(uuidString: uuidString)
    }
}
