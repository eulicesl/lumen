# Lumen App Review Notes Draft

Use this as the starting point for the App Review information field in App Store Connect.
Trim it to only what reviewers need for the final build.

## Reviewer notes

Lumen is a privacy-first native AI assistant for iPhone and iPad.

Important review context:

1. The app does not require account creation or third-party API keys to launch.
2. On supported devices, the app can use Apple Intelligence / Foundation Models locally.
3. The app also supports Ollama. That path requires the user to enter the URL of a separately running Ollama server, such as one hosted on the reviewer's Mac or another machine reachable on the same local network.
4. If no reachable local model endpoint is configured, parts of the experience that depend on AI generation may not produce a response until the reviewer points the app at Apple Intelligence on supported hardware or at a reachable Ollama server.
5. Microphone and speech-recognition permissions are optional and only requested when the reviewer explicitly uses those features. Camera, photo library, and file-import behavior should be re-verified against the final release build and corresponding Info.plist usage descriptions before submission if those features remain enabled.
6. For the final submission, include either a short demo video or a reviewer-accessible test setup if any part of the review depends on Ollama-specific flows.

## Suggested shorter version

Lumen supports local AI through Apple Intelligence on supported devices and through a separately running Ollama server reachable on the user's local network. No account is required. If the reviewer does not configure a reachable local model endpoint, AI-generation features may be unavailable. Microphone and speech-recognition permissions are optional and only requested when those features are used. If review depends on Ollama-specific behavior, include a short demo video or a reviewer-accessible test setup.
