import Foundation

enum ConversationState: Sendable, Equatable {
    case idle
    case generating
    case stopping
    case error(String)

    var isGenerating: Bool {
        switch self {
        case .generating, .stopping: return true
        default: return false
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }

    var displayText: String {
        switch self {
        case .idle:       return ""
        case .generating: return "Generating…"
        case .stopping:   return "Stopping…"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    static func == (lhs: ConversationState, rhs: ConversationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):             return true
        case (.generating, .generating): return true
        case (.stopping, .stopping):     return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}
