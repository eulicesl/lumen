#if os(iOS)
import AVFoundation
import Speech
import Foundation

struct VoiceTranscript: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
}

actor VoiceService {
    static let shared = VoiceService()

    private var recognizer: SFSpeechRecognizer?

    nonisolated(unsafe) private var audioEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?

    private(set) var isRecording = false
    private(set) var microphoneAuthorized = false
    private(set) var speechAuthorized = false

    private var transcriptContinuation: AsyncStream<VoiceTranscript>.Continuation?

    private init() {
        recognizer = SFSpeechRecognizer(locale: .current)
        recognizer?.defaultTaskHint = .dictation
    }

    // MARK: - Authorization

    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        speechAuthorized = speechGranted

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { cont in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        }
        microphoneAuthorized = micGranted
        return speechGranted && micGranted
    }

    var isAvailable: Bool {
        recognizer?.isAvailable ?? false
    }

    // MARK: - Recording

    func startTranscribing() -> AsyncStream<VoiceTranscript> {
        let (stream, continuation) = AsyncStream.makeStream(of: VoiceTranscript.self)
        transcriptContinuation = continuation
        Task { await self.beginSession() }
        return stream
    }

    func stopTranscribing() {
        recognitionTask?.finish()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        transcriptContinuation?.finish()
        transcriptContinuation = nil
    }

    // MARK: - Private

    private func beginSession() {
        guard !isRecording else { return }
        guard let recognizer, recognizer.isAvailable else {
            transcriptContinuation?.finish()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false
            recognitionRequest = request

            let storedContinuation = transcriptContinuation

            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let transcript = VoiceTranscript(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal,
                        confidence: result.bestTranscription.segments.last?.confidence ?? 1.0
                    )
                    storedContinuation?.yield(transcript)
                    if result.isFinal {
                        storedContinuation?.finish()
                    }
                }
                if let error {
                    let nsError = error as NSError
                    let isCancelled = nsError.code == 301
                    if !isCancelled {
                        storedContinuation?.finish()
                    }
                }
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            let capturedRequest = request
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                capturedRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            transcriptContinuation?.finish()
        }
    }
}
#endif
