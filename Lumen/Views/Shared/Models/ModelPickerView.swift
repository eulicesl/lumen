import SwiftUI

struct ModelPickerView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if modelStore.isLoading {
                    loadingSection
                } else if modelStore.availableModels.isEmpty {
                    emptySection
                } else {
                    if !ollamaModels.isEmpty {
                        Section("Ollama (Local)") {
                            ForEach(ollamaModels) { model in
                                modelRow(model)
                            }
                        }
                    }
                    if !appleModels.isEmpty {
                        Section("Apple Intelligence") {
                            ForEach(appleModels) { model in
                                modelRow(model)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Model")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .refreshable {
                await modelStore.refreshModels()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Task { await modelStore.loadModels() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(modelStore.isLoading)
                    .accessibilityLabel("Refresh models")
                    .accessibilityHint("Checks local providers again and reloads the model list")
                }
            }
            .task { await modelStore.loadModels() }
        }
    }

    // MARK: - Rows

    private func modelRow(_ model: AIModel) -> some View {
        Button {
            chatStore.currentModel = model
            dismiss()
        } label: {
            HStack(spacing: LumenSpacing.sm) {
                Image(systemName: model.providerType == .foundationModels
                      ? LumenIcon.appleIntelligence : LumenIcon.ollama)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(LumenType.body)
                        .foregroundStyle(.primary)
                    if let context = model.contextLength {
                        Text("\(context / 1000)K context")
                            .font(LumenType.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if chatStore.currentModel?.id == model.id {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.displayName)
        .accessibilityValue(modelRowAccessibilityValue(model))
        .accessibilityHint("Selects this model for the current conversation")
    }

    // MARK: - Empty / loading

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: LumenSpacing.sm) {
                    ProgressView()
                    Text("Checking providers…")
                        .font(LumenType.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, LumenSpacing.lg)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var emptySection: some View {
        Section {
            ContentUnavailableView {
                Label("No Models Available", systemImage: "cpu")
            } description: {
                Text(emptyStateMessage)
            } actions: {
                Button("Try Again") {
                    Task { await modelStore.refreshModels() }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Filtering

    private var ollamaModels: [AIModel] {
        modelStore.availableModels.filter { $0.providerType == .ollama }
    }

    private var appleModels: [AIModel] {
        modelStore.availableModels.filter { $0.providerType == .foundationModels }
    }

    private var emptyStateMessage: String {
        if let lastError = modelStore.lastError {
            return "\(lastError) You can try again after confirming your Ollama server settings."
        }
        return "Make sure Ollama is running, or that Apple Intelligence is enabled in Settings."
    }

    private func modelRowAccessibilityValue(_ model: AIModel) -> String {
        var parts = [model.providerType == .foundationModels ? "Apple Intelligence" : "Ollama"]
        if let context = model.contextLength {
            parts.append("\(context / 1000)K context")
        }
        if chatStore.currentModel?.id == model.id {
            parts.append("Selected")
        }
        return parts.joined(separator: ". ")
    }
}

#Preview {
    ModelPickerView()
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
        .environment(AppStore.shared)
}
