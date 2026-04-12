import SwiftUI
import PhotosUI
private extension View {
    @ViewBuilder
    func liquidComposerSurface() -> some View {
        #if compiler(>=6.3)
        if #available(iOS 26.0, *) {
            self.glassCard(radius: 22, interactive: true)
        } else {
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        #else
        self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        #endif
    }

    func neutralComposerButtonChrome() -> some View {
        self
            .foregroundStyle(.primary)
            .background(Color(.tertiarySystemFill), in: Circle())
    }

    func destructiveComposerButtonChrome() -> some View {
        self
            .foregroundStyle(.red)
            .background(Color.red.opacity(0.14), in: Circle())
    }

    func primaryComposerButtonChrome() -> some View {
        self
            .foregroundStyle(.white)
            .background(Color.accentColor, in: Circle())
    }
}

struct InputBarView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var inputFocused: Bool
    @State private var showingDocumentImporter = false
    @ScaledMetric(relativeTo: .body) private var mediaButtonSize = 34
    @ScaledMetric(relativeTo: .body) private var primaryActionButtonSize = 32
    @ScaledMetric(relativeTo: .body) private var mediaButtonIconSize = 18
    @ScaledMetric(relativeTo: .body) private var actionButtonIconSize = 16

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
            if chatStore.canRetryLastResponse {
                retryBanner
            }
            if chatStore.isEditingMessage {
                editBanner
            }
            if !chatStore.pendingDocuments.isEmpty {
                DocumentAttachmentRow(
                    documents: chatStore.pendingDocuments,
                    onRemove: removeDocument
                )
                .transition(LumenMotion.moveTransition(edge: .bottom, reduceMotion: reduceMotion))
            }

            #if os(iOS)
            ImageAttachmentRow(images: $selectedImages, onOCR: { image in
                Task { await performOCR(on: image) }
            })
            .animation(
                LumenMotion.animation(LumenAnimation.standard, reduceMotion: reduceMotion),
                value: selectedImages.isEmpty
            )
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

    private var retryBanner: some View {
        HStack(spacing: LumenSpacing.sm) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Last response failed")
                    .font(LumenType.footnote.weight(.semibold))
                if let errorMessage = chatStore.conversationState.errorMessage {
                    Text(errorMessage)
                        .font(LumenType.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button("Retry") {
                Task { await chatStore.retryLastResponse() }
            }
            .font(LumenType.caption.weight(.semibold))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LumenSpacing.md)
        .padding(.top, LumenSpacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Retries the most recent assistant response")
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
        .accessibilityElement(children: .contain)
        .accessibilityHint("Cancel editing or send the updated message to create a branch")
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
                .font(.system(size: mediaButtonIconSize, weight: .semibold))
                .frame(width: mediaButtonSize, height: mediaButtonSize)
                .neutralComposerButtonChrome()
        }
        .buttonStyle(.plain)
        .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
        .contentShape(Rectangle())
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
                .font(.system(size: mediaButtonIconSize, weight: .semibold))
                .frame(width: mediaButtonSize, height: mediaButtonSize)
                .neutralComposerButtonChrome()
        }
        .buttonStyle(.plain)
        .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
        .contentShape(Rectangle())
        .accessibilityLabel("Attach Document")
        .accessibilityHint("Import PDF, text, or source files into the current message")
        .accessibilityValue(chatStore.pendingDocuments.isEmpty ? "No documents attached" : "\(chatStore.pendingDocuments.count) document\(chatStore.pendingDocuments.count == 1 ? "" : "s") attached")
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
            .accessibilityHint(chatStore.isEditingMessage ? "Update your message" : "Enter a prompt or question for the selected conversation")
    }

    // MARK: - Send / Stop button

    #if os(iOS)
    private var voiceButton: some View {
        Button { toggleVoice() } label: {
            voiceButtonIcon
        }
        .buttonStyle(.plain)
        .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
        .contentShape(Rectangle())
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
                        .font(.system(size: mediaButtonIconSize, weight: .semibold))
                        .frame(width: mediaButtonSize, height: mediaButtonSize)
                        .destructiveComposerButtonChrome()
                }
                .buttonStyle(.plain)
                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                .accessibilityLabel("Stop generating response")
                .accessibilityHint("Stops the assistant response in progress")
                .transition(LumenMotion.scaleTransition(reduceMotion: reduceMotion))
            } else {
                if canSend {
                    Button { sendMessage() } label: {
                        Image(systemName: chatStore.isEditingMessage ? "arrow.branch" : LumenIcon.send)
                            .font(.system(size: actionButtonIconSize, weight: .semibold))
                            .frame(width: primaryActionButtonSize, height: primaryActionButtonSize)
                            .primaryComposerButtonChrome()
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                    .accessibilityLabel(chatStore.isEditingMessage ? "Send edited message in new branch" : "Send message")
                    .accessibilityHint(sendButtonAccessibilityHint)
                    .accessibilityValue(sendButtonAccessibilityValue)
                    .transition(LumenMotion.scaleTransition(reduceMotion: reduceMotion))
                } else {
                    #if os(iOS)
                    Button { toggleVoice() } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: actionButtonIconSize, weight: .semibold))
                            .frame(width: primaryActionButtonSize, height: primaryActionButtonSize)
                            .neutralComposerButtonChrome()
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                    .accessibilityLabel("Start voice mode")
                    .accessibilityHint("Begins voice input when there is no text to send")
                    .transition(LumenMotion.scaleTransition(reduceMotion: reduceMotion))
                    #else
                    EmptyView()
                    #endif
                }
            }
        }
        .animation(
            LumenMotion.animation(LumenAnimation.interactive, reduceMotion: reduceMotion),
            value: chatStore.conversationState == .generating
        )
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

    private var sendButtonAccessibilityHint: String {
        if chatStore.isEditingMessage {
            return "Creates a new branch from the edited message and regenerates the response"
        }

        if !chatStore.pendingDocuments.isEmpty || !chatStore.pendingImageData.isEmpty {
            return "Sends the current text and attachments"
        }

        return "Sends the current message"
    }

    private var sendButtonAccessibilityValue: String {
        let textCount = chatStore.inputText.trimmingCharacters(in: .whitespacesAndNewlines).count
        let imageCount = chatStore.pendingImageData.count
        let documentCount = chatStore.pendingDocuments.count

        var parts: [String] = []
        if textCount > 0 {
            parts.append("\(textCount) character\(textCount == 1 ? "" : "s")")
        }
        if imageCount > 0 {
            parts.append("\(imageCount) image\(imageCount == 1 ? "" : "s")")
        }
        if documentCount > 0 {
            parts.append("\(documentCount) document\(documentCount == 1 ? "" : "s")")
        }

        assert(
            !parts.isEmpty,
            "sendButtonAccessibilityValue should only be evaluated when there is sendable content"
        )
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var voiceButtonIcon: some View {
        let icon = Image(systemName: isRecording ? LumenIcon.micActive : LumenIcon.microphone)
            .font(.system(size: actionButtonIconSize, weight: .medium))
            .frame(width: primaryActionButtonSize, height: primaryActionButtonSize)
            .foregroundStyle(isRecording ? Color.red : .primary)
            .background(
                isRecording ? Color.red.opacity(0.14) : Color(.tertiarySystemFill),
                in: Circle()
            )

        if reduceMotion {
            icon
        } else {
            icon.symbolEffect(.pulse, isActive: isRecording)
        }
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let documents: [ImportedDocument]
    let onRemove: (ImportedDocument) -> Void
    @ScaledMetric(relativeTo: .body) private var rowHeight = 88
    @ScaledMetric(relativeTo: .body) private var documentIconSize = 18
    @ScaledMetric(relativeTo: .body) private var removeIconSize = 16

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
        .frame(minHeight: rowHeight)
        .background(.bar)
    }

    private func documentChip(_ document: ImportedDocument) -> some View {
        HStack(spacing: LumenSpacing.sm) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: documentIconSize, weight: .medium))
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
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }

            Button {
                onRemove(document)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: removeIconSize))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
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
