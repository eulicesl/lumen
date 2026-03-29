import SwiftUI

// MARK: - Agent mode configuration panel

struct AgentConfigView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                agentToggleSection
                toolsSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Agent Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var agentToggleSection: some View {
        Section {
            HStack(spacing: LumenSpacing.md) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(chatStore.agentModeEnabled ? Color.accentColor : Color.secondary)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agent Mode")
                        .font(LumenType.body)
                    Text(chatStore.agentModeEnabled ? "Active — tools available" : "Disabled")
                        .font(LumenType.footnote)
                        .foregroundStyle(chatStore.agentModeEnabled ? Color.accentColor : Color.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { chatStore.agentModeEnabled },
                    set: { chatStore.agentModeEnabled = $0 }
                ))
                .labelsHidden()
            }
            .padding(.vertical, 2)
        } footer: {
            Text("When enabled, Lumen can use tools (calculator, date/time, encoders) to assist with your requests.")
        }
    }

    private var toolsSection: some View {
        Section("Available Tools") {
            ForEach(AgentToolRegistry.all, id: \.name) { tool in
                HStack(spacing: LumenSpacing.md) {
                    Image(systemName: iconForTool(tool.name))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.name)
                            .font(LumenType.body)
                            .fontDesign(.monospaced)
                        Text(tool.description)
                            .font(LumenType.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if chatStore.agentModeEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("How it works") {
            VStack(alignment: .leading, spacing: LumenSpacing.sm) {
                instructionRow(number: "1", text: "Send any message — Lumen decides if a tool would help.")
                instructionRow(number: "2", text: "Tool calls and results appear inline in the response.")
                instructionRow(number: "3", text: "Lumen continues with a final answer incorporating the results.")
            }
            .padding(.vertical, LumenSpacing.xs)
        }
    }

    @ViewBuilder
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: LumenSpacing.sm) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())
            Text(text)
                .font(LumenType.body)
                .foregroundStyle(.secondary)
        }
    }

    private func iconForTool(_ name: String) -> String {
        switch name {
        case "datetime":    return "calendar.clock"
        case "calculator":  return "function"
        case "wordcount":   return "textformat.123"
        case "base64":      return "lock.doc"
        case "urlencode":   return "link"
        default:            return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Tool call event bubble (shown inline in chat)

struct AgentToolEventView: View {
    let event: AgentEvent

    var body: some View {
        Group {
            switch event {
            case .toolCall(let name, let input):
                toolCallBubble(name: name, input: input)
            case .toolResult(let name, let result):
                toolResultBubble(name: name, result: result)
            default:
                EmptyView()
            }
        }
    }

    private func toolCallBubble(name: String, input: String) -> some View {
        GlassContainer(
            style: .interactive,
            shape: .roundedRectangle(radius: LumenRadius.md),
            padding: .init(
                top: LumenSpacing.xs,
                leading: LumenSpacing.md,
                bottom: LumenSpacing.xs,
                trailing: LumenSpacing.md
            )
        ) {
            HStack(spacing: LumenSpacing.sm) {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calling **\(name)**")
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                    if !input.isEmpty {
                        Text(input)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: 320, alignment: .leading)
    }

    @ViewBuilder
    private func toolResultBubble(name: String, result: String) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: LumenSpacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("**\(name)** result")
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                    Text(result)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.xs)
            .glassEffect(
                .regular.tint(.green),
                in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
            )
            .frame(maxWidth: 320, alignment: .leading)
        } else {
            HStack(spacing: LumenSpacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("**\(name)** result")
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                    Text(result)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.xs)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: LumenRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.md)
                    .strokeBorder(Color.green.opacity(0.25), lineWidth: 0.5)
            )
            .frame(maxWidth: 320, alignment: .leading)
        }
    }
}

#Preview("Agent Config") {
    AgentConfigView()
        .environment(ChatStore.shared)
}

#Preview("Tool Call") {
    AgentToolEventView(event: .toolCall(name: "calculator", input: "(42 * 2) + 8"))
        .padding()
}

#Preview("Tool Result") {
    AgentToolEventView(event: .toolResult(name: "calculator", result: "92"))
        .padding()
}

