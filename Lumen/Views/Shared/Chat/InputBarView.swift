import SwiftUI
import PhotosUI
private extension View {
    @ViewBuilder
    func liquidComposerSurface() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

struct InputBarView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @FocusState private var inputFocused: Bool
    @State private var showingDocumentImporter = false

    #if os(iOS)
    @State private var selectedImages: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isRecording = false
    @State private var voiceTask: Task<Void, Never>?
    private let voiceService = VoiceService.shared
    #endif

    var body: some View {
        @Bindable var bindableChat = chatStore
        VStack(spacing: LumenSpacing.xs) {
            if chatStore.isEditingMessage {
                editBanner
            }
            if !chatStore.pendingDocuments.isEmpty {
                DocumentAttachmentRow(
                    documents: chatStore.pendingDocuments,
                    onRemove: removeDocument
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            #if os(iOS)
            ImageAttachmentRow(images: $selectedImages, onOCR: { image in
                Task { await performOCR(on: image) }
            })
            .animation(LumenAnimation.standard, value: selectedImages.isEmpty)
            #endif

            HStack(alignment: .bottom, spacing: LumenSpacing.sm) {
                documentButton
                #if os(iOS)
                photoButton
                #endif
                inputField(bindableChat: $bindableChat)
                voiceButton
                sendButton
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.sm)
            .liquidComposerSurface()
            .padding(.horizontal, LumenSpacing.sm)
            .padding(.bottom, 4)
        }
        .padding(.top, 4)
        .background(.bar)
        .onChange(of: selectedImages) { syncPendingImages() }
        .onChange(of: chatStore.editingMessageID) {
            if chatStore.isEditingMessage {
                inputFocused = true
                selectedImages = []
            }
        }
        .fileImporter(
            isPresented: $showingDocumentImporter,
            allowedContentTypes: DocumentImportService.supportedContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleDocumentImport
        )
    }

    private var editBanner: some View {
        HStack(spacing: LumenSpacing.sm) {
            Image(systemName: "arrow.branch")
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Editing earlier message in a new branch")
                    .font(LumenType.footnote.weight(.semibold))
                if let preview = chatStore.editingMessagePreview, !preview.isEmpty {
                    Text(preview)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button("Cancel") {
                cancelEditing()
            }
            .font(LumenType.caption.weight(.semibold))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.top, LumenSpacing.xs)
    }

    // MARK: - Media buttons (iOS only)

    #if os(iOS)
    private var photoButton: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: 4,
            matching: .images
        ) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.12), in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Attach Photo")
        .accessibilityHint("Adds images to the current message")
        .onChange(of: pickerItems) { Task { await loadPickerImages() } }
        .disabled(chatStore.conversationState == .generating)
    }
    #endif

    private var documentButton: some View {
        Button {
            showingDocumentImporter = true
        } label: {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.12), in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Attach Document")
        .accessibilityHint("Import PDF, text, or source files into the current message")
        .disabled(chatStore.conversationState == .generating)
    }

    // MARK: - Input field

    @ViewBuilder
    private func inputField(bindableChat: Bindable<ChatStore>) -> some View {
        TextField("Ask anything", text: bindableChat.inputText, axis: .vertical)
            .font(LumenType.messageBody)
            .lineLimit(1...8)
            .focused($inputFocused)
            .submitLabel(.send)
            .padding(.horizontal, LumenSpacing.xs)
            .padding(.vertical, LumenSpacing.xs)
            .onSubmit {
                #if os(iOS)
                sendMessage()
                #endif
            }
            .disabled(chatStore.selectedConversation == nil)
            .accessibilityLabel(chatStore.isEditingMessage ? "Edit message" : "Message composer")
            .accessibilityHint("Enter a prompt or question for the selected conversation")
            .accessibilityValue(composerAccessibilityValue)
    }

    // MARK: - Send / Stop button

    #if os(iOS)
    private var voiceButton: some View {
        Button { toggleVoice() } label: {
            Image(systemName: isRecording ? LumenIcon.micActive : LumenIcon.microphone)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isRecording ? Color.red : Color.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.10), in: Circle())
                .contentShape(Rectangle())
                .symbolEffect(.pulse, isActive: isRecording)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Voice Input")
        .accessibilityHint(isRecording ? "Stops voice transcription and keeps the current text" : "Starts dictation into the message composer")
        .disabled(chatStore.conversationState == .generating)
    }
    #else
    private var voiceButton: some View { EmptyView() }
    #endif

    private var sendButton: some View {
        Group {
            if chatStore.conversationState == .generating {
                Button { chatStore.stopGeneration() } label: {
                    Image(systemName: LumenIcon.stop)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 34, height: 34)
                        .background(Color.red.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop generating response")
                .accessibilityHint("Stops the assistant response in progress")
                .transition(.scale.combined(with: .opacity))
            } else {
                if canSend {
                    Button { sendMessage() } label: {
                        Image(systemName: chatStore.isEditingMessage ? "arrow.branch" : LumenIcon.send)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(width: 32, height: 32)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(chatStore.isEditingMessage ? "Send edited message in new branch" : "Send message")
                    .accessibilityHint(sendButtonAccessibilityHint)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    #if os(iOS)
                    Button { toggleVoice() } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.16), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start voice mode")
                    .accessibilityHint("Begins voice input when there is no text to send")
                    .transition(.scale.combined(with: .opacity))
                    #else
                    EmptyView()
                    #endif
                }
            }
        }
        .animation(LumenAnimation.interactive, value: chatStore.conversationState == .generating)
    }

    // MARK: - Logic

    private var canSend: Bool {
        let hasText = !chatStore.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImages = !chatStore.pendingImageData.isEmpty
        let hasDocuments = !chatStore.pendingDocuments.isEmpty
        return (hasText || hasImages || hasDocuments)
            && chatStore.selectedConversation != nil
            && chatStore.currentModel != nil
            && chatStore.conversationState != .generating
    }

    private var composerAccessibilityValue: String {
        let trimmedText = chatStore.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let textState = trimmedText.isEmpty ? "Empty" : "Contains text"
        let imageCount = chatStore.pendingImageData.count
        let documentCount = chatStore.pendingDocuments.count
        return "\(textState), \(imageCount) attached image\(imageCount == 1 ? "" : "s"), \(documentCount) attached document\(documentCount == 1 ? "" : "s")"
    }

    private var sendButtonAccessibilityHint: String {
        if !chatStore.pendingDocuments.isEmpty || !chatStore.pendingImageData.isEmpty {
            return "Sends the current text and attachments"
        }

        return chatStore.isEditingMessage
            ? "Creates a new branch from the edited message and regenerates the response"
            : "Sends the current message"
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

    private func cancelEditing() {
        chatStore.cancelEditing()
        #if os(iOS)
        selectedImages = []
        #endif
    }

    private func handleDocumentImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task { await importDocuments(from: urls) }
        case .failure(let error):
            appStore.activeAlert = AppAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    @MainActor
    private func importDocuments(from urls: [URL]) async {
        var imported: [ImportedDocument] = []
        var failures: [String] = []

        for url in urls {
            do {
                let document = try await DocumentImportService.shared.importDocument(from: url)
                imported.append(document)
            } catch {
                failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if !imported.isEmpty {
            chatStore.pendingDocuments.append(contentsOf: imported)
        }

        if !failures.isEmpty {
            let message = failures.prefix(3).joined(separator: "\n")
            appStore.activeAlert = AppAlert(
                title: "Some Documents Couldn't Be Imported",
                message: message
            )
        }
    }

    private func removeDocument(_ document: ImportedDocument) {
        chatStore.pendingDocuments.removeAll { $0.id == document.id }
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

private struct DocumentAttachmentRow: View {
    let documents: [ImportedDocument]
    let onRemove: (ImportedDocument) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LumenSpacing.sm) {
                ForEach(documents) { document in
                    documentChip(document)
                }
            }
            .padding(.horizontal, LumenSpacing.md)
            .padding(.vertical, LumenSpacing.xs)
        }
        .frame(height: 88)
        .background(.bar)
    }

    private func documentChip(_ document: ImportedDocument) -> some View {
        HStack(spacing: LumenSpacing.sm) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(LumenType.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(document.previewText)
                    .font(LumenType.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button {
                onRemove(document)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(document.fileName)")
            .accessibilityHint("Removes this document from the message")
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.vertical, LumenSpacing.sm)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        Spacer()
        InputBarView()
            .environment(ChatStore.shared)
            .environment(AppStore.shared)
    }
}
