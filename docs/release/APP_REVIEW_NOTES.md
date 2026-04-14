# Lumen App Review Notes Draft

Use this as the starting point for the App Review information field in App Store Connect.
Trim it to only what reviewers need for the final build.

## Reviewer notes

Lumen is a privacy-first native AI assistant for iPhone and iPad.

Important review context:

1. The primary review path is Apple Intelligence on supported hardware. No account, login, or third-party API key is required for that path.
2. On a supported device with Apple Intelligence enabled, launch Lumen, complete onboarding, start a new chat, and send a prompt. This is the intended default reviewer flow.
3. Lumen also offers optional Ollama Local and Ollama Cloud providers for users who want to connect their own infrastructure or hosted account. Those providers are advanced, optional, and not required to review the app.
4. Ollama Local requires the user to enter the URL of a separately running Ollama server, such as one hosted on the reviewer's Mac or another machine reachable on the same local network. Ollama Cloud requires the user to provide their own API key.
5. If the review device does not support Apple Intelligence, or if Apple Intelligence is unavailable on that device, AI-generation features will require an optional Ollama provider to be configured by the user.
6. Microphone and speech-recognition permissions are optional and only requested when the reviewer explicitly uses those features. Camera, photo library, and file-import behavior should be re-verified against the final release build and corresponding Info.plist usage descriptions before submission if those features remain enabled.
7. If review needs to cover an Ollama-specific path, include a short demo video or reviewer-accessible test setup rather than making the default review depend on custom infrastructure.

## Suggested shorter version

Lumen’s primary review path uses Apple Intelligence on supported devices with no account or external credentials required. Reviewers can launch the app, complete onboarding, start a chat, and send a prompt using Apple Intelligence. Ollama Local and Ollama Cloud are optional advanced providers for users who want to connect their own infrastructure or hosted account, and they are not required for standard review. Microphone and speech-recognition permissions are optional and only requested when those features are used.
