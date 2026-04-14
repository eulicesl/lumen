# Lumen App Review Notes

Final text for the **App Review Information → Notes** field in App Store Connect for Lumen v1.0 (build 1).

Verify this against the exact release candidate build before submission. If a feature listed below is removed or disabled in the final build, update this file and the App Store Connect field in the same pass.

---

## Text to paste into App Store Connect

> Lumen is a privacy-first native AI assistant for iPhone and iPad. The primary reviewer path uses Apple Intelligence on supported hardware and requires no account, no login, and no third-party API key.
>
> Reviewer steps on a device with Apple Intelligence enabled:
>
> 1. Launch Lumen.
> 2. Complete onboarding (no account required).
> 3. Start a new chat.
> 4. Send a prompt such as "Help me plan a two-day trip to San Diego." Apple Intelligence will generate the reply on-device.
>
> Ollama Local and Ollama Cloud are optional advanced providers for users who prefer to route requests to their own local network server or their own hosted Ollama account. They are not required for review and are hidden behind explicit provider selection. If a reviewer wants to exercise an Ollama path specifically, the app exposes fields for a server URL or API key, but the default review path above does not depend on them.
>
> If the review device does not support Apple Intelligence, AI-generation features require the user to configure an Ollama provider. In that case, please use a device that supports Apple Intelligence so the default reviewer path above applies.
>
> Microphone and speech-recognition permissions are requested only when the reviewer uses the voice-input feature explicitly. They are optional for core review.
>
> Lumen does not operate a backend, analytics pipeline, or crash reporter. No content is transmitted to Lumen-operated infrastructure. If a user enables the optional Ollama Cloud provider, chat content is transmitted to `https://ollama.com` using the user's own Ollama Cloud API key; Lumen is the transmission vehicle but the endpoint is the user's own account. The App Privacy questionnaire discloses this as user-opt-in User Content collection used for App Functionality.

---

## Internal notes (do not paste into App Store Connect)

### Reviewer device recommendation

Recommend a device in Apple's supported Apple Intelligence list (iPhone 15 Pro, iPhone 15 Pro Max, iPhone 16 series, iPad with M1 or later, Mac with Apple silicon running iOS 26 / iPadOS 26 / macOS 26 Tahoe). This keeps the default reviewer path credential-free.

### Optional-provider review path

If Apple Intelligence is unavailable on the review device and Apple chooses to test an Ollama path anyway:

- **Ollama Local:** user supplies the URL of a separately-running Ollama server on their local network. Example value: `http://192.168.1.10:11434`. Lumen does not ship or embed Ollama.
- **Ollama Cloud:** user supplies their own Ollama Cloud API key. Lumen does not ship or embed credentials.

Neither of these is a standard consumer path; the default iPhone user is expected to use Apple Intelligence.

### Permission re-verification checklist (before each submission)

- [ ] `NSMicrophoneUsageDescription` matches current in-app behavior.
- [ ] `NSSpeechRecognitionUsageDescription` matches current in-app behavior.
- [ ] If camera or photo-library selection remains enabled in the build, the corresponding usage descriptions are present and accurate in `Info.plist`.
- [ ] `PrivacyInfo.xcprivacy` still declares zero collected data types.
- [ ] No new networking SDK has been added since the last review.

### If review questions the Ollama path

Short answer to have ready: Ollama is entirely user-controlled. The user chooses the server, the user stores their own API key on-device, and Lumen never sees or proxies credentials or content through developer infrastructure.
