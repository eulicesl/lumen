import Foundation
import Observation

@Observable
@MainActor
final class MemoryStore {
    static let shared = MemoryStore()
    private nonisolated static let maxIndexEntries = 12
    private nonisolated static let defaultRelevantLimit = 6

    private(set) var memories: [MemoryItem] = []
    var isEnabled: Bool = true
    private let storageKey = "lumen.memories"
    private let enabledKey = "lumen.memories.enabled"
    private let isTesting: Bool

    private init() {
        isTesting = false
        loadFromDisk()
        isEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Creates an isolated, ephemeral instance backed by an in-memory array.
    /// Only for use in unit tests.
    static func forTesting() -> MemoryStore {
        MemoryStore(testing: true)
    }

    private init(testing: Bool) {
        isTesting = testing
        // Intentionally skips disk load — memories stay in-memory only
    }

    // MARK: - Computed

    var activeMemories: [MemoryItem] { memories.filter(\.isActive) }

    func memories(in category: MemoryCategory) -> [MemoryItem] {
        memories.filter { $0.category == category }
    }

    /// Formatted context string injected into the system prompt.
    /// Keeps a compact index and a relevance-scored subset for the current prompt.
    var contextString: String {
        contextString(for: "")
    }

    func contextString(for prompt: String, relevantLimit: Int = MemoryStore.defaultRelevantLimit) -> String {
        guard isEnabled, !activeMemories.isEmpty else { return "" }

        let indexLines = activeMemories
            .prefix(MemoryStore.maxIndexEntries)
            .map { "- [\($0.category.rawValue)] \(truncate($0.content, to: 90))" }
            .joined(separator: "\n")

        let relevant = relevantMemories(for: prompt, limit: relevantLimit)
        let relevantLines = relevant.map { "- \($0.content)" }.joined(separator: "\n")

        return """
        User memory index (compact):
        \(indexLines)

        Most relevant memory hints for this request:
        \(relevantLines)

        Treat memory as hints and prioritize the current request if there is conflict.
        """
    }

    func relevantMemories(for prompt: String, limit: Int = MemoryStore.defaultRelevantLimit) -> [MemoryItem] {
        let active = activeMemories
        guard !active.isEmpty else { return [] }

        let clampedLimit = max(1, min(limit, active.count))
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryTokens = tokenSet(from: normalizedPrompt)
        let canPhraseMatch = normalizedPrompt.count >= 2

        if queryTokens.isEmpty, !canPhraseMatch {
            return Array(active.prefix(clampedLimit))
        }

        let queryLower = normalizedPrompt.lowercased()
        let scored = active.map { item in
            let contentLower = item.content.lowercased()
            let itemTokens = tokenSet(from: item.content)
            let overlap = queryTokens.reduce(into: 0) { count, token in
                if itemTokens.contains(token) || canSubstringMatch(token, in: contentLower) {
                    count += 1
                }
            }
            let phraseBoost = (canPhraseMatch && contentLower.contains(queryLower)) ? 4 : 0
            let categoryBoost = item.category == .preference ? 1 : 0
            return (
                item: item,
                score: overlap * 3 + phraseBoost + categoryBoost,
                hasQuerySignal: overlap > 0 || phraseBoost > 0
            )
        }

        let top = scored
            .sorted {
                if $0.score == $1.score {
                    return ($0.item.lastUsedAt ?? $0.item.createdAt) > ($1.item.lastUsedAt ?? $1.item.createdAt)
                }
                return $0.score > $1.score
            }
            .prefix(clampedLimit)

        if top.allSatisfy({ !$0.hasQuerySignal }) {
            return Array(active.prefix(clampedLimit))
        }

        return top.map(\.item)
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
        guard !isTesting else { return }
        guard let data = try? JSONEncoder().encode(memories) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func tokenSet(from text: String) -> Set<String> {
        let tokens = text
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter(shouldIndexToken)

        return Set(tokens)
    }

    private func shouldIndexToken(_ token: String) -> Bool {
        token.count >= 2 || token.unicodeScalars.contains(where: { !$0.isASCII })
    }

    private func canSubstringMatch(_ token: String, in contentLower: String) -> Bool {
        guard token.count > 2 || token.unicodeScalars.contains(where: { !$0.isASCII }) else {
            return false
        }

        return contentLower.contains(token)
    }

    private func truncate(_ text: String, to maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength)) + "…"
    }
}
