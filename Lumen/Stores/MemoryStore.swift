import Foundation
import Observation

@Observable
@MainActor
final class MemoryStore {
    static let shared = MemoryStore()

    private(set) var memories: [MemoryItem] = []
    var isEnabled: Bool = true
    private let storageKey = "lumen.memories"
    private let enabledKey = "lumen.memories.enabled"

    private init() {
        loadFromDisk()
        isEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    // MARK: - Computed

    var activeMemories: [MemoryItem] { memories.filter(\.isActive) }

    func memories(in category: MemoryCategory) -> [MemoryItem] {
        memories.filter { $0.category == category }
    }

    /// Formatted context string injected into the system prompt
    var contextString: String {
        guard isEnabled, !activeMemories.isEmpty else { return "" }
        let items = activeMemories.map { "- \($0.content)" }.joined(separator: "\n")
        return "Here is what you know about the user:\n\(items)"
    }

    // MARK: - CRUD

    @discardableResult
    func add(content: String, category: MemoryCategory = .fact) -> MemoryItem {
        let item = MemoryItem(content: content, category: category)
        memories.insert(item, at: 0)
        saveToDisk()
        return item
    }

    func delete(_ item: MemoryItem) {
        memories.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func delete(offsets: IndexSet) {
        memories.remove(atOffsets: offsets)
        saveToDisk()
    }

    func toggleActive(_ item: MemoryItem) {
        guard let i = memories.firstIndex(of: item) else { return }
        memories[i].isActive.toggle()
        saveToDisk()
    }

    func update(_ item: MemoryItem, content: String, category: MemoryCategory) {
        guard let i = memories.firstIndex(of: item) else { return }
        memories[i].content = content
        memories[i].category = category
        saveToDisk()
    }

    func toggleEnabled() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
    }

    func markUsed(_ item: MemoryItem) {
        guard let i = memories.firstIndex(of: item) else { return }
        memories[i].lastUsedAt = Date()
        saveToDisk()
    }

    func clearAll() {
        memories = []
        saveToDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([MemoryItem].self, from: data) else { return }
        memories = saved
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(memories) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
