import SwiftUI
import PhotosUI

struct InputBarView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @State private var showingModelPicker = false
    @FocusState private var inputFocused: Bool

    #if os(iOS)
    @State private var selectedImages: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isRecording = false
    @State private var voiceTask: Task<Void, Never>?
    private let voiceService = VoiceService.shared
    #endif

    var body: some View {
        @Bindable var bindableChat = chatStore
        VStack(spacing: 0) {
            #if os(iOS)
            ImageAttachmentRow(images: $selectedImages, onOCR: { image in
                Task { await performOCR(on: image) }
            })
            .animation(LumenAnimation.standard, value: selectedImages.isEmpty)
            #endif

            Divider()
            HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
                #if os(iOS)
                mediaButtons
                #endif
                modelChip
                inputField(bindableChat: bindableChat)
                sendButton
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.sm)
            .padding(.bottom, LumenSpacing.xs)
        }
        .background(.bar)
        .onChange(of: selectedImages) { syncPendingImages() }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Media buttons (iOS only)

    #if os(iOS)
    private var mediaButtons: some View {
        HStack(spacing: LumenSpacing.xs) {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 4,
                matching: .images
            ) {
                Image(systemName: LumenIcon.photo)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Attach Photo")
            .onChange(of: pickerItems) { Task { await loadPickerImages() } }
            .disabled(chatStore.conversationState == .generating)

            Button { toggleVoice() } label: {
                Image(systemName: isRecording ? LumenIcon.micActive : LumenIcon.microphone)
                    .font(.system(size: 20))
                    .foregroundStyle(isRecording ? Color.red : Color.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .symbolEffect(.pulse, isActive: isRecording)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRecording ? "Stop Recording" : "Start Voice Input")
            .disabled(chatStore.conversationState == .generating)
        }
    }
    #endif

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

    // MARK: - Logic

    private var canSend: Bool {
        let hasText = !chatStore.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImages = !chatStore.pendingImageData.isEmpty
        return (hasText || hasImages)
            && chatStore.selectedConversation != nil
            && chatStore.currentModel != nil
            && chatStore.conversationState != .generating
    }

    private func sendMessage() {
        guard canSend else { return }
        HapticEngine.impact(.medium)
        #if os(iOS)
        selectedImages = []
        #endif
        Task { await chatStore.send() }
    }

    private func syncPendingImages() {
        #if os(iOS)
        Task {
            var result: [Data] = []
            for image in selectedImages {
                if let data = await ImageService.shared.prepareForAPI(image) {
                    result.append(data)
                }
            }
            chatStore.pendingImageData = result
        }
        #endif
    }

    #if os(iOS)
    private func loadPickerImages() async {
        var loaded: [UIImage] = []
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        if !loaded.isEmpty { selectedImages = loaded }
        pickerItems = []
    }

    private func toggleVoice() {
        if isRecording {
            stopVoice()
        } else {
            startVoice()
        }
    }

    private func startVoice() {
        isRecording = true
        voiceTask = Task {
            let granted = await voiceService.requestPermissions()
            guard granted else {
                isRecording = false
                return
            }
            let stream = await voiceService.startTranscribing()
            for await result in stream {
                if Task.isCancelled { break }
                chatStore.inputText = result.text
            }
            isRecording = false
        }
    }

    private func stopVoice() {
        voiceTask?.cancel()
        voiceTask = nil
        Task { await voiceService.stopTranscribing() }
        isRecording = false
    }

    private func performOCR(on image: UIImage) async {
        guard let text = try? await ImageService.shared.extractText(from: image),
              !text.isEmpty else { return }
        let prefix = chatStore.inputText.isEmpty ? "" : "\n"
        chatStore.inputText += prefix + text
    }
    #endif
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
