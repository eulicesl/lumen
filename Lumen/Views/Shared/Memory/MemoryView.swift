import SwiftUI

struct MemoryView: View {
    @Environment(MemoryStore.self) private var memoryStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showingAddSheet = false
    @State private var editingItem: MemoryItem? = nil
    @State private var selectedCategory: MemoryCategory? = nil
    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            List {
                enabledToggle(store: memoryStore)

                if !memoryStore.memories.isEmpty {
                    ForEach(visibleCategories, id: \.self) { category in
                        let items = filteredItems(in: category)
                        if !items.isEmpty {
                            Section {
                                ForEach(items) { item in
                                    memoryRow(item)
                                }
                                .onDelete { offsets in
                                    deleteItems(offsets: offsets, in: category)
                                }
                            } header: {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    }
                } else {
                    emptyState
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Memory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchQuery, prompt: "Search memories…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Memory")
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !memoryStore.memories.isEmpty {
                        Menu {
                            Button("All Categories") { selectedCategory = nil }
                            Divider()
                            ForEach(MemoryCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    Label(cat.rawValue, systemImage: cat.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Filter by Category")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMemoryView { content, category in
                    memoryStore.add(content: content, category: category)
                }
            }
            .sheet(item: $editingItem) { item in
                EditMemoryView(item: item) { content, category in
                    memoryStore.update(item, content: content, category: category)
                }
            }
        }
    }

    // MARK: - Enable toggle

    @ViewBuilder
    private func enabledToggle(store: MemoryStore) -> some View {
        Section {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Enabled")
                    Text("Lumen remembers facts about you across conversations")
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { memoryStore.isEnabled },
                    set: { _ in memoryStore.toggleEnabled() }
                ))
                .labelsHidden()
            }
            .padding(.vertical, 2)
        } footer: {
            Text("When enabled, \(memoryStore.activeMemories.count) active memor\(memoryStore.activeMemories.count == 1 ? "y is" : "ies are") injected into every conversation.")
        }
    }

    // MARK: - Memory row

    @ViewBuilder
    private func memoryRow(_ item: MemoryItem) -> some View {
        HStack(spacing: LumenSpacing.md) {
            Image(systemName: item.category.icon)
                .foregroundStyle(item.isActive ? Color.accentColor : Color.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(LumenType.body)
                    .foregroundStyle(item.isActive ? .primary : .secondary)
                    .strikethrough(!item.isActive, color: .secondary)

                if let used = item.lastUsedAt {
                    Text("Used \(used, formatter: relativeFormatter)")
                        .font(LumenType.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()

            if !item.isActive {
                Text("Off")
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, LumenSpacing.xs)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editingItem = item }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.content)
        .accessibilityValue(memoryRowAccessibilityValue(item))
        .accessibilityHint("Double-tap to edit. Swipe for enable or delete actions.")
        .swipeActions(edge: .leading) {
            Button {
                memoryStore.toggleActive(item)
            } label: {
                Label(item.isActive ? "Disable" : "Enable",
                      systemImage: item.isActive ? "eye.slash" : "eye")
            }
            .tint(item.isActive ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                memoryStore.delete(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        Section {
            VStack(spacing: LumenSpacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundStyle(.quaternary)
                Text("No memories yet")
                    .font(.title3.weight(.semibold))
                Text("Add facts about yourself so Lumen can personalize every conversation.")
                    .font(dynamicTypeSize.isAccessibilitySize ? LumenType.body : LumenType.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Button("Add First Memory") { showingAddSheet = true }
                    .buttonStyle(.bordered)
            }
            .padding(.vertical, LumenSpacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Filtering

    private var visibleCategories: [MemoryCategory] {
        if let cat = selectedCategory { return [cat] }
        return MemoryCategory.allCases
    }

    private func filteredItems(in category: MemoryCategory) -> [MemoryItem] {
        memoryStore.memories(in: category).filter { item in
            guard !searchQuery.isEmpty else { return true }
            return item.content.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private func deleteItems(offsets: IndexSet, in category: MemoryCategory) {
        let items = filteredItems(in: category)
        for i in offsets {
            memoryStore.delete(items[i])
        }
    }

    private var relativeFormatter: RelativeDateTimeFormatter {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }

    private func memoryRowAccessibilityValue(_ item: MemoryItem) -> String {
        let status = item.isActive ? "On" : "Off"
        if let used = item.lastUsedAt {
            return "\(item.category.rawValue). \(status). Used \(relativeFormatter.localizedString(for: used, relativeTo: .now))."
        }
        return "\(item.category.rawValue). \(status)."
    }
}

// MARK: - Add memory sheet

struct AddMemoryView: View {
    let onSave: (String, MemoryCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var category: MemoryCategory = .fact

    var body: some View {
        NavigationStack {
            Form {
                Section("Remember that…") {
                    TextEditor(text: $content)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Memory content")
                        .accessibilityHint("Enter the fact or preference Lumen should remember")
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(MemoryCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(content.trimmingCharacters(in: .whitespacesAndNewlines), category)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Edit memory sheet

struct EditMemoryView: View {
    let item: MemoryItem
    let onSave: (String, MemoryCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(MemoryStore.self) private var memoryStore
    @State private var content: String
    @State private var category: MemoryCategory

    init(item: MemoryItem, onSave: @escaping (String, MemoryCategory) -> Void) {
        self.item = item
        self.onSave = onSave
        _content = State(initialValue: item.content)
        _category = State(initialValue: item.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Memory") {
                    TextEditor(text: $content)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Memory content")
                        .accessibilityHint("Edit the fact or preference Lumen should remember")
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(MemoryCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Button(role: .destructive) {
                        memoryStore.delete(item)
                        dismiss()
                    } label: {
                        Label("Delete Memory", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(content.trimmingCharacters(in: .whitespacesAndNewlines), category)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Memory") {
    MemoryView()
        .environment(MemoryStore.shared)
}

#Preview("Add Memory") {
    AddMemoryView { _, _ in }
}

#Preview("Edit Memory") {
    EditMemoryView(
        item: MemoryItem(
            content: "I prefer concise technical answers.",
            category: .preference,
            lastUsedAt: .now
        )
    ) { _, _ in }
    .environment(MemoryStore.shared)
}
