import SwiftUI

struct ModelComparisonView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ModelStore.self) private var modelStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var modelA: AIModel?
    @State private var modelB: AIModel?
    @State private var prompt = ""
    @State private var responseA = ComparisonResponse()
    @State private var responseB = ComparisonResponse()
    @State private var taskA: Task<Void, Never>?
    @State private var taskB: Task<Void, Never>?
    @FocusState private var promptFocused: Bool

    private var isRunning: Bool { responseA.isStreaming || responseB.isStreaming }
    private var hasResponses: Bool { !responseA.content.isEmpty || !responseB.content.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modelSelectors
                Divider()
                if hasResponses {
                    responsePanels
                } else {
                    promptPlaceholder
                }
                Divider()
                promptBar
            }
            .navigationTitle("Compare Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if hasResponses {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { clearAll() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                if modelStore.availableModels.count >= 2 {
                    modelA = modelStore.availableModels[0]
                    modelB = modelStore.availableModels[1]
                } else if modelStore.availableModels.count == 1 {
                    modelA = modelStore.availableModels[0]
                }
            }
        }
    }

    // MARK: - Model selectors

    private var modelSelectors: some View {
        HStack(spacing: LumenSpacing.xs) {
            ModelSelectorButton(label: "Model A", model: $modelA, available: modelStore.availableModels)
            Divider().frame(height: 36)
            ModelSelectorButton(label: "Model B", model: $modelB, available: modelStore.availableModels)
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.sm)
    }

    // MARK: - Response panels (adaptive layout)

    private var responsePanels: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 600
            Group {
                if isWide {
                    HStack(alignment: .top, spacing: 1) {
                        responsePanel(
                            label: modelA?.shortName ?? "Model A",
                            response: responseA,
                            color: .blue
                        )
                        Divider()
                        responsePanel(
                            label: modelB?.shortName ?? "Model B",
                            response: responseB,
                            color: .purple
                        )
                    }
                } else {
                    ScrollView {
                        VStack(spacing: LumenSpacing.md) {
                            responsePanel(
                                label: modelA?.shortName ?? "Model A",
                                response: responseA,
                                color: .blue
                            )
                            responsePanel(
                                label: modelB?.shortName ?? "Model B",
                                response: responseB,
                                color: .purple
                            )
                        }
                        .padding(LumenSpacing.md)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func responsePanel(label: String, response: ComparisonResponse, color: Color) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenSpacing.sm) {
                HStack {
                    Text(label)
                        .font(LumenType.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                        .padding(.horizontal, LumenSpacing.sm)
                        .padding(.vertical, LumenSpacing.xxs)
                        .background(color.opacity(0.12), in: Capsule())

                    Spacer()

                    if response.isStreaming {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if let ttft = response.timeToFirstToken {
                        Text(String(format: "%.2fs TTFT", ttft))
                            .font(LumenType.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }

                if response.content.isEmpty && !response.isStreaming {
                    Text(response.error ?? "Waiting…")
                        .font(LumenType.messageBody)
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(AttributedString.fromMarkdown(response.content))
                        .font(LumenType.messageBody)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if response.isStreaming {
                        StreamingPulse()
                    }

                    if let count = response.tokenCount, count > 0 {
                        Text("\(count) tokens")
                            .font(LumenType.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(LumenSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Placeholder

    private var promptPlaceholder: some View {
        VStack(spacing: LumenSpacing.md) {
            Spacer()
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)
                .symbolRenderingMode(.hierarchical)
            Text("Compare two models side by side")
                .font(LumenType.body)
                .foregroundStyle(.secondary)
            Text("Select models above, then enter a prompt")
                .font(LumenType.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Prompt bar

    private var promptBar: some View {
        HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
            TextField("Enter a prompt to compare…", text: $prompt, axis: .vertical)
                .font(LumenType.messageBody)
                .lineLimit(1...6)
                .focused($promptFocused)
                .padding(.horizontal, LumenSpacing.sm)
                .padding(.vertical, LumenSpacing.xs)
                .glassCard(radius: 14, interactive: true)

            if isRunning {
                Button { stopAll() } label: {
                    Image(systemName: LumenIcon.stop)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            } else {
                Button { runComparison() } label: {
                    Image(systemName: LumenIcon.send)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(canRun ? Color.accentColor : Color.secondary)
                        .frame(width: 36, height: 36)
                        .background(canRun ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canRun)
            }
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.sm)
        .padding(.bottom, LumenSpacing.xs)
        .background(.bar)
        .animation(
            LumenMotion.animation(LumenAnimation.interactive, reduceMotion: reduceMotion),
            value: isRunning
        )
    }

    // MARK: - Logic

    private var canRun: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (modelA != nil || modelB != nil)
            && !isRunning
    }

    private func runComparison() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        clearResponses()
        promptFocused = false

        let userMsg = ChatMessage.userMessage(text)
        let startTime = Date()

        if let modelA {
            taskA = Task { @MainActor in
                await stream(userMsg, model: modelA, side: .a, startTime: startTime)
            }
        }
        if let modelB {
            taskB = Task { @MainActor in
                await stream(userMsg, model: modelB, side: .b, startTime: startTime)
            }
        }
    }

    private enum Side { case a, b }

    @MainActor
    private func stream(
        _ message: ChatMessage,
        model: AIModel,
        side: Side,
        startTime: Date
    ) async {
        switch side {
        case .a: responseA.isStreaming = true
        case .b: responseB.isStreaming = true
        }

        let aiService = AIService.shared
        let stream = await aiService.chat(
            messages: [message],
            model: model,
            options: ChatOptions()
        )
        do {
            for try await token in stream {
                if Task.isCancelled { break }
                switch side {
                case .a:
                    if responseA.timeToFirstToken == nil { responseA.timeToFirstToken = Date().timeIntervalSince(startTime) }
                    responseA.content += token.text
                    if token.isComplete { responseA.tokenCount = token.tokenCount }
                case .b:
                    if responseB.timeToFirstToken == nil { responseB.timeToFirstToken = Date().timeIntervalSince(startTime) }
                    responseB.content += token.text
                    if token.isComplete { responseB.tokenCount = token.tokenCount }
                }
            }
        } catch {
            if !Task.isCancelled {
                switch side {
                case .a: responseA.error = error.localizedDescription
                case .b: responseB.error = error.localizedDescription
                }
            }
        }

        switch side {
        case .a: responseA.isStreaming = false
        case .b: responseB.isStreaming = false
        }
    }

    private func stopAll() {
        taskA?.cancel(); taskA = nil
        taskB?.cancel(); taskB = nil
        responseA.isStreaming = false
        responseB.isStreaming = false
    }

    private func clearResponses() {
        responseA = ComparisonResponse()
        responseB = ComparisonResponse()
    }

    private func clearAll() {
        stopAll()
        clearResponses()
        prompt = ""
    }
}

// MARK: - Model selector button

private struct ModelSelectorButton: View {
    let label: String
    @Binding var model: AIModel?
    let available: [AIModel]
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            VStack(alignment: .center, spacing: 2) {
                Text(label)
                    .font(LumenType.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(model?.shortName ?? "Select")
                        .font(LumenType.body)
                        .fontWeight(.medium)
                        .foregroundStyle(model != nil ? .primary : .secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LumenSpacing.xs)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                List {
                    ForEach(available) { m in
                        Button {
                            model = m
                            showingPicker = false
                        } label: {
                            HStack {
                                Text(m.name)
                                Spacer()
                                if model?.id == m.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationTitle("Select \(label)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { showingPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Response state

struct ComparisonResponse {
    var content: String = ""
    var isStreaming: Bool = false
    var timeToFirstToken: TimeInterval? = nil
    var tokenCount: Int? = nil
    var error: String? = nil
}

private struct ModelSelectorButtonPreviewHost: View {
    @State private var model: AIModel? = .appleFoundationModel

    var body: some View {
        ModelSelectorButton(
            label: "Model A",
            model: $model,
            available: [.appleFoundationModel, .ollamaPlaceholder]
        )
        .padding()
    }
}

#Preview("Model Comparison") {
    ModelComparisonView()
        .environment(ChatStore.shared)
        .environment(ModelStore.shared)
}

#Preview("Model Selector") {
    ModelSelectorButtonPreviewHost()
}
