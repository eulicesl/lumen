#if os(iOS)
import SwiftUI

struct VoiceInputView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(AppStore.self) private var appStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRecording = false
    @State private var transcript = ""
    @State private var transcriptHistory: [String] = []
    @State private var hasPermission = false
    @State private var showingPermissionAlert = false
    @State private var recordingTask: Task<Void, Never>?

    private let voiceService = VoiceService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                transcriptArea
                Divider()
                controlBar
            }
            .navigationTitle("Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !transcriptHistory.isEmpty {
                        Button("Clear") {
                            transcriptHistory = []
                            transcript = ""
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .task { await checkPermissions() }
            .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Lumen needs microphone and speech recognition access for voice input. Enable them in Settings → Privacy.")
            }
        }
    }

    // MARK: - Transcript area

    private var transcriptArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: LumenSpacing.md) {
                    ForEach(transcriptHistory.indices, id: \.self) { i in
                        Text(transcriptHistory[i])
                            .font(LumenType.messageBody)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, LumenSpacing.lg)
                    }

                    if !transcript.isEmpty || isRecording {
                        Text(transcript.isEmpty ? "Listening…" : transcript)
                            .font(LumenType.title)
                            .fontWeight(.medium)
                            .foregroundStyle(transcript.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, LumenSpacing.lg)
                            .id("live")
                    }

                    if transcript.isEmpty && !isRecording && transcriptHistory.isEmpty {
                        emptyPrompt
                    }
                }
                .padding(.vertical, LumenSpacing.lg)
            }
            .onChange(of: transcript) { proxy.scrollTo("live", anchor: .bottom) }
        }
    }

    private var emptyPrompt: some View {
        ContentUnavailableView(
            "Voice Input",
            systemImage: LumenIcon.microphone,
            description: Text("Tap the microphone to start dictation.")
        )
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Control bar

    private var controlBar: some View {
        VStack(spacing: LumenSpacing.lg) {
            if isRecording {
                VoiceWaveformView(isAnimating: true, barCount: 7)
                    .transition(LumenMotion.scaleTransition(reduceMotion: reduceMotion))
            }

            HStack(spacing: LumenSpacing.xxl) {
                Button {
                    if !transcript.isEmpty {
                        transcriptHistory.append(transcript)
                        transcript = ""
                    }
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title)
                        .foregroundStyle(!transcript.isEmpty ? Color.accentColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                .accessibilityLabel("Save transcript segment")
                .accessibilityHint("Moves the current dictated text into transcript history")
                .disabled(transcript.isEmpty)

                Button {
                    toggleRecording()
                } label: {
                    VoicePulseView(isActive: isRecording)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRecording ? "Stop voice input" : "Start voice input")
                .accessibilityHint(isRecording ? "Stops dictation" : "Starts dictation")
                .accessibilityValue(transcript.isEmpty ? (isRecording ? "Listening" : "Idle") : transcript)

                Button {
                    sendTranscript()
                } label: {
                    Image(systemName: LumenIcon.send)
                        .font(.title)
                        .foregroundStyle(!transcript.isEmpty ? Color.accentColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .frame(minWidth: LumenLayout.minTouchTarget, minHeight: LumenLayout.minTouchTarget)
                .accessibilityLabel("Send transcript")
                .accessibilityHint("Uses the dictated text in chat")
                .disabled(transcript.isEmpty)
            }

            if isRecording {
                Text("Tap mic to stop")
                    .font(LumenType.footnote)
                    .foregroundStyle(.secondary)
            } else if !transcript.isEmpty {
                Text("Tap send to use this transcript in chat")
                    .font(LumenType.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, LumenSpacing.xl)
        .padding(.vertical, LumenSpacing.lg)
        .animation(
            LumenMotion.animation(LumenAnimation.standard, reduceMotion: reduceMotion),
            value: isRecording
        )
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard hasPermission else {
            showingPermissionAlert = true
            return
        }
        transcript = ""
        isRecording = true

        recordingTask = Task {
            let stream = await voiceService.startTranscribing()
            for await result in stream {
                if Task.isCancelled { break }
                transcript = result.text
                if result.isFinal && !result.text.isEmpty {
                    transcriptHistory.append(result.text)
                    transcript = ""
                }
            }
            isRecording = false
        }
    }

    private func stopRecording() {
        recordingTask?.cancel()
        recordingTask = nil
        Task { await voiceService.stopTranscribing() }
        isRecording = false
    }

    private func sendTranscript() {
        let text = ([transcript] + transcriptHistory).filter { !$0.isEmpty }.joined(separator: " ")
        guard !text.isEmpty else { return }
        chatStore.inputText = text
        transcript = ""
        transcriptHistory = []
        stopRecording()
        appStore.selectedTab = .chat
        Task { await chatStore.send() }
    }

    private func checkPermissions() async {
        hasPermission = await voiceService.requestPermissions()
    }
}

#Preview {
    VoiceInputView()
        .environment(ChatStore.shared)
        .environment(AppStore.shared)
}
#endif
