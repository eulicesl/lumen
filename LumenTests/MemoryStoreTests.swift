import Foundation
import Testing
@testable import Lumen

@Suite("MemoryStore")
@MainActor
struct MemoryStoreTests {

    @Test("Add a memory item and retrieve it")
    func addMemory() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "I prefer dark mode", category: .preference)
        #expect(store.memories.count == 1)
        #expect(store.memories.first?.id == item.id)
        #expect(store.memories.first?.content == "I prefer dark mode")
        #expect(store.memories.first?.category == .preference)
        #expect(store.memories.first?.isActive == true)
    }

    @Test("Delete a memory item")
    func deleteMemory() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "To delete", category: .custom)
        #expect(store.memories.count == 1)
        store.delete(item)
        #expect(store.memories.isEmpty)
    }

    @Test("Toggle active state")
    func toggleActive() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "Some fact", category: .fact)
        #expect(store.memories.first?.isActive == true)
        store.toggleActive(item)
        #expect(store.memories.first?.isActive == false)
        store.toggleActive(store.memories.first!)
        #expect(store.memories.first?.isActive == true)
    }

    @Test("Update content and category")
    func updateMemory() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "Original", category: .fact)
        store.update(item, content: "Updated", category: .preference)
        #expect(store.memories.first?.content == "Updated")
        #expect(store.memories.first?.category == .preference)
    }

    @Test("Context string is empty when store is disabled")
    func contextStringWhenDisabled() {
        let store = MemoryStore.forTesting()
        store.add(content: "Fact one", category: .fact)
        store.isEnabled = false
        #expect(store.contextString.isEmpty)
    }

    @Test("Context string includes active memories when enabled")
    func contextStringIncludesActiveMemories() {
        let store = MemoryStore.forTesting()
        store.add(content: "I use Swift", category: .fact)
        store.isEnabled = true
        let ctx = store.contextString
        #expect(ctx.contains("I use Swift"))
        #expect(ctx.contains("User memory index (compact)"))
        #expect(ctx.contains("Most relevant memory hints for this request"))
    }

    @Test("Inactive memories excluded from context string")
    func inactiveMemoriesExcluded() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "Hidden fact", category: .fact)
        store.toggleActive(item)
        #expect(store.memories.first?.isActive == false)
        #expect(!store.contextString.contains("Hidden fact"))
    }

    @Test("Relevant memories prioritize token overlap with prompt")
    func relevantMemoriesByPrompt() {
        let store = MemoryStore.forTesting()
        store.add(content: "I prefer compact Swift syntax and native iOS APIs", category: .preference)
        store.add(content: "My favorite meal is ramen", category: .fact)
        store.add(content: "I am planning a hiking trip", category: .context)

        let relevant = store.relevantMemories(for: "Help me improve Swift iOS code quality", limit: 1)
        #expect(relevant.count == 1)
        #expect(relevant.first?.content.contains("Swift") == true)
    }

    @Test("Context string for prompt focuses the relevant section")
    func promptScopedContext() {
        let store = MemoryStore.forTesting()
        store.add(content: "I use Swift every day", category: .fact)
        store.add(content: "Remember to buy groceries", category: .reminder)

        let ctx = store.contextString(for: "Can you review my Swift code?", relevantLimit: 1)
        let sections = ctx.components(separatedBy: "Most relevant memory hints for this request:\n")
        #expect(sections.count == 2)

        if sections.count == 2 {
            let relevantSection = sections[1].components(separatedBy: "\n\nTreat memory as hints").first ?? ""
            #expect(relevantSection.contains("Swift"))
            #expect(!relevantSection.contains("groceries"))
        }
    }

    @Test("activeMemories returns only active items")
    func activeMemoriesFilter() {
        let store = MemoryStore.forTesting()
        let a = store.add(content: "Active", category: .fact)
        let b = store.add(content: "Inactive", category: .fact)
        store.toggleActive(b)
        #expect(store.activeMemories.count == 1)
        #expect(store.activeMemories.first?.id == a.id)
    }

    @Test("clearAll removes every item")
    func clearAllItems() {
        let store = MemoryStore.forTesting()
        store.add(content: "A", category: .fact)
        store.add(content: "B", category: .preference)
        store.add(content: "C", category: .context)
        #expect(store.memories.count == 3)
        store.clearAll()
        #expect(store.memories.isEmpty)
    }

    @Test("memories(in:) filters by category")
    func filterByCategory() {
        let store = MemoryStore.forTesting()
        store.add(content: "Pref 1", category: .preference)
        store.add(content: "Fact 1", category: .fact)
        store.add(content: "Fact 2", category: .fact)
        let facts = store.memories(in: .fact)
        #expect(facts.count == 2)
        let prefs = store.memories(in: .preference)
        #expect(prefs.count == 1)
    }

    @Test("forTesting instance does not persist to UserDefaults")
    func testingInstanceIsEphemeral() {
        let store = MemoryStore.forTesting()
        store.add(content: "Ephemeral", category: .fact)
        let another = MemoryStore.forTesting()
        #expect(another.memories.isEmpty, "Each forTesting() instance starts empty")
    }
}

@Suite("AppStore security")
@MainActor
struct AppStoreSecurityTests {

    @Test("Migrates legacy Ollama bearer token from UserDefaults to secure storage")
    func migratesLegacyToken() {
        let suiteName = "AppStoreSecurityTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("legacy-token", forKey: "ollamaBearerToken")

        let secretStore = InMemorySecretStore()
        let store = AppStore(userDefaults: defaults, secretStore: secretStore)

        #expect(store.ollamaBearerToken == "legacy-token")
        #expect(secretStore.storage["ollamaBearerToken"] == "legacy-token")
        #expect(defaults.string(forKey: "ollamaBearerToken") == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Saving Ollama bearer token stores only the secure copy")
    func savesTokenSecurely() {
        let suiteName = "AppStoreSecurityTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let secretStore = InMemorySecretStore()
        let store = AppStore(userDefaults: defaults, secretStore: secretStore)
        store.saveOllamaBearerToken("new-token")

        #expect(store.ollamaBearerToken == "new-token")
        #expect(secretStore.storage["ollamaBearerToken"] == "new-token")
        #expect(defaults.string(forKey: "ollamaBearerToken") == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Clearing Ollama bearer token removes the secure copy")
    func clearsTokenSecurely() {
        let suiteName = "AppStoreSecurityTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let secretStore = InMemorySecretStore()
        secretStore.storage["ollamaBearerToken"] = "existing-token"

        let store = AppStore(userDefaults: defaults, secretStore: secretStore)
        store.saveOllamaBearerToken("")

        #expect(store.ollamaBearerToken.isEmpty)
        #expect(secretStore.storage["ollamaBearerToken"] == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }
}

private final class InMemorySecretStore: SecretStore {
    var storage: [String: String] = [:]

    func string(forKey key: String) throws -> String? {
        storage[key]
    }

    func setString(_ value: String, forKey key: String) throws {
        storage[key] = value
    }

    func removeValue(forKey key: String) throws {
        storage.removeValue(forKey: key)
    }
}

@Suite("ModelStore reliability")
struct ModelStoreReliabilityTests {

    @Test("Network failures produce a user-facing Ollama status message")
    func ollamaNetworkErrorMessage() {
        let message = ModelStore.ollamaErrorMessage(
            for: AIProviderError.networkError(URLError(.cannotConnectToHost)),
            urlString: "http://mac-studio.local:11434"
        )

        #expect(message.contains("mac-studio.local"))
        #expect(message.contains("Can't reach Ollama"))
    }

    @Test("Timed-out Ollama requests mention reachability guidance")
    func ollamaTimeoutMessage() {
        let message = ModelStore.ollamaErrorMessage(
            for: AIProviderError.networkError(URLError(.timedOut)),
            urlString: "http://localhost:11434"
        )

        #expect(message.contains("Timed out"))
        #expect(message.contains("reachable"))
    }

    @Test("Available status reports the model count")
    func availableStatusTitle() {
        let status = OllamaConnectionStatus.available(modelCount: 3)

        #expect(status.title == "3 models available")
        #expect(status.detail == "Connected to your local Ollama server.")
        #expect(status.isAvailable)
    }
}
