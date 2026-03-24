import Foundation

enum MessageRole: String, Sendable, Codable, CaseIterable {
    case user      = "user"
    case assistant = "assistant"
    case system    = "system"

    var displayName: String {
        switch self {
        case .user:      return "You"
        case .assistant: return "Assistant"
        case .system:    return "System"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .user:      return "Your message"
        case .assistant: return "Assistant message"
        case .system:    return "System message"
        }
    }
}
