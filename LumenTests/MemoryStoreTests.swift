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
        #expect(ctx.contains("Here is what you know about the user"))
    }

    @Test("Inactive memories excluded from context string")
    func inactiveMemoriesExcluded() {
        let store = MemoryStore.forTesting()
        let item = store.add(content: "Hidden fact", category: .fact)
        store.toggleActive(item)
        #expect(store.memories.first?.isActive == false)
        #expect(!store.contextString.contains("Hidden fact"))
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
