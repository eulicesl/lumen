import Foundation
import Observation

@Observable
@MainActor
final class LibraryStore {
    static let shared = LibraryStore()

    private(set) var prompts: [SavedPrompt] = []
    private let storageKey = "lumen.saved_prompts"

    private init() {
        loadFromDisk()
    }

    // MARK: - Computed

    var favorites: [SavedPrompt] {
        prompts.filter(\.isFavorite)
    }

    var customPrompts: [SavedPrompt] {
        prompts.filter { !$0.isBuiltIn }
    }

    func prompts(in category: PromptCategory) -> [SavedPrompt] {
        prompts.filter { $0.category == category }
    }

    // MARK: - CRUD

    func add(title: String, content: String, category: PromptCategory) {
        let prompt = SavedPrompt(
            title: title,
            content: content,
            category: category,
            isBuiltIn: false
        )
        prompts.append(prompt)
        saveToDisk()
    }

    func delete(_ prompt: SavedPrompt) {
        guard !prompt.isBuiltIn else { return }
        prompts.removeAll { $0.id == prompt.id }
        saveToDisk()
    }

    func toggleFavorite(_ prompt: SavedPrompt) {
        guard let i = prompts.firstIndex(of: prompt) else { return }
        prompts[i].isFavorite.toggle()
        saveToDisk()
    }

    func update(_ prompt: SavedPrompt, title: String, content: String, category: PromptCategory) {
        guard let i = prompts.firstIndex(of: prompt) else { return }
        prompts[i].title = title
        prompts[i].content = content
        prompts[i].category = category
        saveToDisk()
    }

    // MARK: - Persistence (UserDefaults — lightweight, no SwiftData needed)

    private func loadFromDisk() {
        var all = SavedPrompt.builtIns
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let custom = try? JSONDecoder().decode([SavedPrompt].self, from: data) {
            all.append(contentsOf: custom)

            for saved in custom where saved.isFavorite {
                if let bi = all.firstIndex(where: { $0.id == saved.id && $0.isBuiltIn }) {
                    all[bi].isFavorite = saved.isFavorite
                }
            }
        }

        if let data = UserDefaults.standard.data(forKey: storageKey + ".favorites"),
           let favIDs = try? JSONDecoder().decode([UUID].self, from: data) {
            for id in favIDs {
                if let i = all.firstIndex(where: { $0.id == id }) {
                    all[i].isFavorite = true
                }
            }
        }

        prompts = all
    }

    private func saveToDisk() {
        let custom = prompts.filter { !$0.isBuiltIn }
        if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        let favIDs = prompts.filter(\.isFavorite).map(\.id)
        if let data = try? JSONEncoder().encode(favIDs) {
            UserDefaults.standard.set(data, forKey: storageKey + ".favorites")
        }
    }
}
