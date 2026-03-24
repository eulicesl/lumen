import Foundation
import WidgetKit

// MARK: - Shared widget conversation model
// This mirrors WidgetConversation in LumenWidget/RecentConversationWidget.swift.
// Add THIS file to the main Lumen target.
// Add the LumenWidget version only to the LumenWidget extension target.

struct WidgetConversation: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let preview: String
    let updatedAt: Date
}

// MARK: - App Group shared store (write side — main app)

enum WidgetSharedStore {
    private static let suiteName = "group.ai.lumen"
    private static let key = "widget.recentConversations"

    static func save(_ conversations: [WidgetConversation]) {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static var recentConversationTitle: String? {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
              let conversations = try? JSONDecoder().decode([WidgetConversation].self, from: data) else {
            return nil
        }
        return conversations.first?.title
    }
}
