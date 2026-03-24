import SwiftUI

struct InputBarView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @State private var showingModelPicker = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        @Bindable var bindableChat = chatStore
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
                modelChip
                inputField(bindableChat: bindableChat)
                sendButton
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.sm)
            .padding(.bottom, LumenSpacing.xs)
        }
        .background(.bar)
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Model chip

    private var modelChip: some View {
        Button {
            showingModelPicker = true
        } label: {
            HStack(spacing: LumenSpacing.xxs) {
                Image(systemName: chatStore.currentModel?.providerType == .foundationModels
                      ? LumenIcon.appleIntelligence : LumenIcon.ollama)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(chatStore.currentModel?.shortName ?? "Model")
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, LumenSpacing.sm)
            .padding(.vertical, LumenSpacing.xs)
            .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(chatStore.conversationState == .generating)
    }

    // MARK: - Input field

    @ViewBuilder
    private func inputField(bindableChat: Bindable<ChatStore>) -> some View {
        TextField("Message", text: bindableChat.inputText, axis: .vertical)
            .font(LumenType.messageBody)
            .lineLimit(1...8)
            .focused($inputFocused)
            .submitLabel(.send)
            .onSubmit {
                #if os(iOS)
                sendMessage()
                #endif
            }
            .disabled(chatStore.selectedConversation == nil)
            .padding(.horizontal, LumenSpacing.sm)
            .padding(.vertical, LumenSpacing.xs)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.input))
    }

    // MARK: - Send / Stop button

    private var sendButton: some View {
        Group {
            if chatStore.conversationState == .generating {
                Button { chatStore.stopGeneration() } label: {
                    Image(systemName: LumenIcon.stop)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                Button { sendMessage() } label: {
                    Image(systemName: LumenIcon.send)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(canSend ? Color.accentColor : Color.secondary)
                        .frame(width: 36, height: 36)
                        .background(canSend ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(LumenAnimation.interactive, value: chatStore.conversationState == .generating)
    }

    private var canSend: Bool {
        !chatStore.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && chatStore.selectedConversation != nil
            && chatStore.currentModel != nil
            && chatStore.conversationState != .generating
    }

    private func sendMessage() {
        guard canSend else { return }
        Task { await chatStore.send() }
    }
}

// MARK: - LumenRadius input

private extension LumenRadius {
    static var input: CGFloat { 14 }
}

#Preview {
    VStack {
        Spacer()
        InputBarView()
            .environment(ChatStore.shared)
            .environment(AppStore.shared)
    }
}
