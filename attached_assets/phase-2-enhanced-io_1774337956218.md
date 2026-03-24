# Phase 2: Enhanced Input & Output

> Voice, images, documents, and camera — matching ChatGPT and Claude input capabilities.

**Duration:** Week 6-8
**Outcome:** Users can interact with AI via voice, images, camera, and documents in addition to text.
**Dependencies:** Phase 1 complete (core chat working)

---

## Objectives

1. Implement voice input using iOS 26 SpeechAnalyzer
2. Implement text-to-speech (read aloud) for AI responses
3. Implement image attachment and analysis
4. Implement camera capture for real-time input
5. Implement document/PDF text extraction via Vision OCR
6. Build a dedicated Voice tab experience

---

## User Stories

### US2.1 — Voice Input (Speech-to-Text)
> As a user, I want to dictate my messages instead of typing.

**Acceptance Criteria:**
- Microphone button in chat input bar
- Tap to start recording, tap again to stop (or automatic silence detection)
- Real-time transcription appears in the input field as the user speaks
- Language selector with 70+ languages
- SpeechAnalyzer provides confidence scores and speaker diarization
- Transcribed text can be edited before sending
- Visual audio waveform during recording

### US2.2 — Voice Conversation Mode
> As a user, I want to have a hands-free voice conversation with the AI.

**Acceptance Criteria:**
- Dedicated Voice tab with full-screen recording interface
- Continuous listening mode: user speaks → AI responds via TTS → user speaks again
- Push-to-talk alternative mode
- Visual feedback: waveform animation while recording, pulsing while AI speaks
- Conversation is persisted as text in a chat conversation
- Transcription history with playback

### US2.3 — Text-to-Speech (Read Aloud)
> As a user, I want the AI to read its responses out loud.

**Acceptance Criteria:**
- Read aloud button on assistant messages
- AVSpeechSynthesizer with system voice selection
- Visual indicator showing which message is being read
- Stop button to cancel speech
- Voice preference configurable in Settings
- Respects system Do Not Disturb / Silent mode

### US2.4 — Image Attachment
> As a user, I want to send images to the AI for analysis.

**Acceptance Criteria:**
- Photo button in input bar opens photo picker
- Selected image shows as thumbnail above input field
- Remove button on thumbnail to deselect
- Image sent alongside text message to vision-capable models
- If current model doesn't support images, show warning and offer model switch
- Multiple images supported (up to 4 per message)

### US2.5 — Camera Capture
> As a user, I want to use my camera to capture content for AI analysis.

**Acceptance Criteria:**
- Camera button in input bar
- Opens native camera interface
- Captured photo added as attachment
- Quick-use cases: document scanning, whiteboard capture, receipt scanning
- Camera permission handled gracefully with explanation

### US2.6 — Document & PDF Analysis
> As a user, I want to extract text from documents and PDFs for AI processing.

**Acceptance Criteria:**
- File picker accessible from attachment menu
- PDF text extraction via PDFKit
- Image-based document text extraction via Vision framework OCR
- Extracted text shown in expandable preview before sending
- Large documents truncated with clear indicator of what was included
- Supported formats: PDF, PNG, JPG, HEIC

---

## Technical Implementation

### SpeechAnalyzer Integration (iOS 26)

```swift
// Services/VoiceService.swift

import Speech
#if canImport(_SpeechAnalyzer_SwiftUI)
import _SpeechAnalyzer_SwiftUI
#endif

actor VoiceService {
    static let shared = VoiceService()

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startTranscription(language: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        // iOS 26 SpeechAnalyzer for advanced features
        // Fallback to SFSpeechRecognizer for basic transcription
        // Yield TranscriptionResult with:
        //   - text: String (current transcription)
        //   - isVolatile: Bool (still being processed)
        //   - confidence: Float
        //   - speakers: [Speaker] (diarization)
    }
}

struct TranscriptionResult: Sendable {
    let text: String
    let isVolatile: Bool
    let confidence: Float
    let segments: [TranscriptionSegment]
}

struct TranscriptionSegment: Sendable {
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Float
    let speakerID: Int?
}
```

### Text-to-Speech Service

```swift
// Services/SpeechSynthesisService.swift

import AVFoundation

@Observable
@MainActor
final class SpeechSynthesisService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechSynthesisService()

    var isSpeaking: Bool = false
    var currentMessageID: UUID?

    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, messageID: UUID, voice: AVSpeechSynthesisVoice? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        currentMessageID = messageID
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentMessageID = nil
    }

    func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
    }
}
```

### Image & Document Processing

```swift
// Services/MediaService.swift

import Vision
import PDFKit

actor MediaService {
    static let shared = MediaService()

    /// Extract text from an image using Vision OCR
    func extractText(from imageData: Data) async throws -> String {
        guard let image = CIImage(data: imageData) else {
            throw MediaError.invalidImage
        }
        let request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = ImageRequestHandler(image, options: [:])
        let results = try await handler.perform(request)
        return results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }

    /// Extract text from a PDF
    func extractText(from pdfData: Data) async throws -> String {
        guard let document = PDFDocument(data: pdfData) else {
            throw MediaError.invalidPDF
        }
        var text = ""
        for i in 0..<min(document.pageCount, 50) {  // Limit to 50 pages
            if let page = document.page(at: i) {
                text += page.string ?? ""
                text += "\n\n"
            }
        }
        return text
    }
}
```

### TranscriptionStore

```swift
@Observable
@MainActor
final class TranscriptionStore {
    static let shared = TranscriptionStore()

    enum State {
        case idle
        case recording
        case processing
        case speaking
    }

    var state: State = .idle
    var currentTranscription: String = ""
    var volatileText: String = ""           // Provisional/changing text
    var audioLevels: [Float] = []            // Waveform data
    var selectedLanguage: Locale = .current
    var transcriptionHistory: [TranscriptionSession] = []
    var recordingDuration: TimeInterval = 0

    func startRecording() async { ... }
    func stopRecording() async { ... }
    func startContinuousConversation() async { ... }
}
```

---

## UI Components

### Voice Tab Layout

```
┌──────────────────────────────────┐
│          Voice Assistant          │
│                                  │
│    ┌──────────────────────┐      │
│    │                      │      │
│    │   [Audio Waveform]   │      │  ← Real-time waveform
│    │                      │      │
│    └──────────────────────┘      │
│                                  │
│    "How can I help you today?"   │  ← Status text
│                                  │
│    ┌──────────────────────┐      │
│    │  Transcribed text... │      │  ← Live transcription
│    │  (volatile in gray)  │      │
│    └──────────────────────┘      │
│                                  │
│         ┌──────────┐             │
│         │  ● REC   │             │  ← Record button (large, 56pt)
│         └──────────┘             │
│                                  │
│   [🌐 English ▾]  [History]     │  ← Language picker + history
└──────────────────────────────────┘
```

### Image Attachment Preview

```
┌──────────────────────────────────┐
│ ┌─────┐ ┌─────┐                 │
│ │ img │ │ img │   (thumbnails)  │  ← Horizontal scroll if > 2
│ │  ✕  │ │  ✕  │                 │
│ └─────┘ └─────┘                 │
│ ┌──────────────────────────┐    │
│ │ What's in these images?  │ ▲  │  ← Input field + send
│ └──────────────────────────┘    │
│ [📷] [🎤] [📎]     Llava ▾     │
└──────────────────────────────────┘
```

---

## Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `Services/VoiceService.swift` | SpeechAnalyzer/SFSpeechRecognizer |
| 2 | `Services/SpeechSynthesisService.swift` | Text-to-speech |
| 3 | `Services/MediaService.swift` | Image/PDF text extraction |
| 4 | `Stores/TranscriptionStore.swift` | Voice recording state |
| 5 | `Models/TranscriptionModels.swift` | Transcription types |
| 6 | `Views/Shared/Voice/VoiceView.swift` | Main voice tab |
| 7 | `Views/Shared/Voice/AudioWaveformView.swift` | Waveform visualization |
| 8 | `Views/Shared/Voice/RecordingButton.swift` | Animated record button |
| 9 | `Views/Shared/Voice/LanguageSelectorView.swift` | Language picker |
| 10 | `Views/Shared/Voice/TranscriptionHistoryView.swift` | Past transcriptions |
| 11 | `Views/Shared/Chat/ImageAttachmentView.swift` | Image preview row |
| 12 | `Views/Shared/Chat/ReadAloudView.swift` | TTS playback indicator |
| 13 | `Views/Shared/Chat/CameraButton.swift` | Camera capture trigger |
| 14 | `Views/Shared/Chat/DocumentPickerView.swift` | File picker wrapper |
| 15 | `Views/Shared/Settings/VoiceSettingsView.swift` | Voice preferences |
| 16 | `Data/SwiftData/TranscriptionSD.swift` | Persistent transcription |
| 17 | `LumenTests/VoiceServiceTests.swift` | Voice service tests |
| 18 | `LumenTests/MediaServiceTests.swift` | OCR/PDF tests |

**Total: 18 files**

---

## Acceptance Criteria

### Voice Input
- [ ] Microphone button in chat input starts recording
- [ ] Real-time transcription appears as user speaks
- [ ] Volatile (provisional) text shown in lighter color
- [ ] Stop recording finalizes transcription into input field
- [ ] Language selector with 70+ languages
- [ ] Audio permission requested with clear explanation
- [ ] Waveform visualization during recording

### Voice Conversation Mode
- [ ] Voice tab provides full-screen recording interface
- [ ] Continuous mode: speak → AI responds via TTS → listen again
- [ ] Push-to-talk mode as alternative
- [ ] Conversation persisted as text messages
- [ ] Recording duration displayed

### Text-to-Speech
- [ ] Read aloud button on assistant messages
- [ ] Visual indicator during speech
- [ ] Stop button cancels
- [ ] Voice selection in settings
- [ ] Silent mode / DND respected

### Image & Camera
- [ ] Photo picker accessible from input bar
- [ ] Camera button opens native camera
- [ ] Image thumbnails with remove button
- [ ] Up to 4 images per message
- [ ] Vision model requirement shown when needed
- [ ] Images sent to AI and response received

### Document Analysis
- [ ] File picker for PDFs and images
- [ ] PDF text extraction with page limit
- [ ] Image OCR with Vision framework
- [ ] Extracted text preview before sending
- [ ] Error handling for corrupted/empty files

### Testing
- [ ] VoiceService mock tests
- [ ] MediaService OCR tests (with sample image)
- [ ] At least 10 new passing tests

---

## Privacy Considerations

- Voice data is processed on-device only (SpeechAnalyzer runs locally)
- No audio recordings are sent to any server
- Images are sent to the configured AI provider (Ollama = your server, FM = on-device)
- Camera permission clearly explains usage
- Microphone permission clearly explains usage
- Users can disable voice features entirely

---

*Phase 2 transforms Lumen from a text chat into a multimodal assistant. The voice experience should feel as natural as talking to Siri, but more capable.*
