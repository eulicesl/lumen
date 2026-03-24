import SwiftUI

struct PromptLibraryView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @Environment(LibraryStore.self) private var libraryStore

    @State private var selectedCategory: PromptCategory? = nil
    @State private var searchQuery = ""
    @State private var showingAddPrompt = false
    @State private var selectedPrompt: SavedPrompt? = nil
    @State private var showingDeleteConfirm = false
    @State private var promptToDelete: SavedPrompt? = nil

    var body: some View {
        NavigationStack {
            List {
                if !libraryStore.favorites.isEmpty && searchQuery.isEmpty && selectedCategory == nil {
                    Section {
                        ForEach(libraryStore.favorites) { prompt in
                            promptRow(prompt)
                        }
                    } header: {
                        Label("Favorites", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }

                ForEach(visibleCategories, id: \.self) { category in
                    let items = filteredPrompts(in: category)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { prompt in
                                promptRow(prompt)
                            }
                        } header: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Prompt Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchQuery, prompt: "Search prompts…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPrompt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    categoryPicker
                }
            }
            .sheet(isPresented: $showingAddPrompt) {
                AddPromptView { title, content, category in
                    libraryStore.add(title: title, content: content, category: category)
                }
            }
            .sheet(item: $selectedPrompt) { prompt in
                PromptDetailView(prompt: prompt) { text in
                    usePrompt(text)
                }
            }
            .confirmationDialog(
                "Delete Prompt",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let p = promptToDelete { libraryStore.delete(p) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        Menu {
            Button("All Categories") { selectedCategory = nil }
            Divider()
            ForEach(PromptCategory.allCases, id: \.self) { cat in
                Button {
                    selectedCategory = cat
                } label: {
                    Label(cat.rawValue, systemImage: cat.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if let cat = selectedCategory {
                    Text(cat.rawValue)
                        .font(LumenType.caption)
                }
            }
        }
    }

    // MARK: - Prompt row

    @ViewBuilder
    private func promptRow(_ prompt: SavedPrompt) -> some View {
        Button {
            selectedPrompt = prompt
        } label: {
            HStack(spacing: LumenSpacing.md) {
                Image(systemName: prompt.category.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
                    Text(prompt.title)
                        .font(LumenType.body)
                        .foregroundStyle(.primary)
                    Text(prompt.content)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if prompt.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                libraryStore.toggleFavorite(prompt)
            } label: {
                Label(
                    prompt.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: prompt.isFavorite ? "star.slash" : "star"
                )
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing) {
            if !prompt.isBuiltIn {
                Button(role: .destructive) {
                    promptToDelete = prompt
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Button {
                usePrompt(prompt.content)
            } label: {
                Label("Use", systemImage: "arrow.up.circle")
            }
            .tint(.accentColor)
        }
    }

    // MARK: - Filtering

    private var visibleCategories: [PromptCategory] {
        if let cat = selectedCategory { return [cat] }
        return PromptCategory.allCases
    }

    private func filteredPrompts(in category: PromptCategory) -> [SavedPrompt] {
        libraryStore.prompts(in: category).filter { prompt in
            if searchQuery.isEmpty { return true }
            let q = searchQuery.lowercased()
            return prompt.title.lowercased().contains(q) || prompt.content.lowercased().contains(q)
        }
    }

    // MARK: - Use prompt

    private func usePrompt(_ text: String) {
        chatStore.inputText = text
        selectedPrompt = nil
        appStore.selectedTab = .chat
    }
}

// MARK: - Prompt detail sheet

struct PromptDetailView: View {
    let prompt: SavedPrompt
    let onUse: (String) -> Void
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var editedContent: String

    init(prompt: SavedPrompt, onUse: @escaping (String) -> Void) {
        self.prompt = prompt
        self.onUse = onUse
        _editedContent = State(initialValue: prompt.content)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LumenSpacing.lg) {
                    HStack {
                        Label(prompt.category.rawValue, systemImage: prompt.category.icon)
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, LumenSpacing.sm)
                            .padding(.vertical, LumenSpacing.xxs)
                            .background(.regularMaterial, in: Capsule())
                        Spacer()
                    }

                    TextEditor(text: $editedContent)
                        .font(LumenType.messageBody)
                        .frame(minHeight: 200)
                        .padding(LumenSpacing.sm)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md))

                    LumenButton("Use This Prompt", style: .primary) {
                        onUse(editedContent)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)

                    if !prompt.isBuiltIn {
                        LumenButton("Save Changes", style: .secondary) {
                            libraryStore.update(
                                prompt,
                                title: prompt.title,
                                content: editedContent,
                                category: prompt.category
                            )
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(LumenSpacing.lg)
            }
            .navigationTitle(prompt.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        libraryStore.toggleFavorite(prompt)
                    } label: {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(prompt.isFavorite ? .yellow : .secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Add prompt sheet

struct AddPromptView: View {
    let onSave: (String, String, PromptCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var category: PromptCategory = .custom

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Prompt title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(PromptCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("Prompt Text") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(title, content, category)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PromptLibraryView()
        .environment(ChatStore.shared)
        .environment(AppStore.shared)
        .environment(LibraryStore.shared)
}
