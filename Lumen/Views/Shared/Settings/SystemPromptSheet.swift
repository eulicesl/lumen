import SwiftUI

struct SystemPromptSheet: View {
    let conversation: Conversation
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss

    @State private var promptText: String
    @FocusState private var editorFocused: Bool

    init(conversation: Conversation) {
        self.conversation = conversation
        _promptText = State(initialValue: conversation.systemPrompt ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                description
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.top, LumenSpacing.md)
                    .padding(.bottom, LumenSpacing.sm)

                TextEditor(text: $promptText)
                    .font(LumenType.body)
                    .focused($editorFocused)
                    .padding(LumenSpacing.sm)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md))
                    .padding(.horizontal, LumenSpacing.md)
                    .frame(maxHeight: .infinity)

                characterCount
                    .padding(.horizontal, LumenSpacing.md)
                    .padding(.vertical, LumenSpacing.xs)
            }
            .navigationTitle("System Prompt")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(promptText == (conversation.systemPrompt ?? ""))
                }
                if !promptText.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) { promptText = "" }
                    }
                }
            }
        }
        .onAppear { editorFocused = true }
    }

    // MARK: - Sub-views

    private var description: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.xxs) {
            Text("Guides how Lumen responds in this conversation.")
                .font(LumenType.footnote)
                .foregroundStyle(.secondary)
            Text("Leave empty to use the default behaviour.")
                .font(LumenType.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    private var characterCount: some View {
        HStack {
            Spacer()
            Text("\(promptText.count) characters")
                .font(LumenType.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await chatStore.setSystemPrompt(trimmed.isEmpty ? nil : trimmed, for: conversation) }
        HapticEngine.notification(.success)
        dismiss()
    }
}

#Preview {
    SystemPromptSheet(
        conversation: Conversation(
            title: "Swift help",
            systemPrompt: "You are a Swift expert. Be concise and show code examples."
        )
    )
    .environment(ChatStore.shared)
}
