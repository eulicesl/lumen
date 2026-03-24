import Foundation

// MARK: - Memory category

enum MemoryCategory: String, CaseIterable, Codable, Sendable {
    case preference = "Preference"
    case fact       = "Fact"
    case context    = "Context"
    case reminder   = "Reminder"
    case custom     = "Custom"

    var icon: String {
        switch self {
        case .preference: return "person.fill"
        case .fact:       return "lightbulb.fill"
        case .context:    return "doc.text.fill"
        case .reminder:   return "bell.fill"
        case .custom:     return "star.fill"
        }
    }
}

// MARK: - MemoryItem

struct MemoryItem: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var content: String
    var category: MemoryCategory
    var isActive: Bool
    let createdAt: Date
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        content: String,
        category: MemoryCategory = .fact,
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    static func == (lhs: MemoryItem, rhs: MemoryItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
