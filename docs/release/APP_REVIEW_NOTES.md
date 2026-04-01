# Lumen App Review Notes Draft

Use this as the starting point for the App Review information field in App Store Connect.
Trim it to only what reviewers need for the final build.

## Reviewer notes

Lumen is a privacy-first native AI assistant for iPhone and iPad.

Important review context:

1. The app does not require account creation or third-party API keys to launch.
2. On supported devices, the app can use Apple Intelligence / Foundation Models locally.
3. The app also supports Ollama. That path requires the user to enter the URL of an Ollama server running on the same device or on the user's local network.
4. If no reachable local model is configured, parts of the experience that depend on AI generation may not produce a response until the reviewer points the app at a local model endpoint.
5. Microphone, photo library, camera, and file import permissions are optional and only requested when the reviewer explicitly uses those features.

## Suggested shorter version

Lumen supports local AI through Apple Intelligence on supported devices and Ollama on the user's local network. No account is required. If the reviewer does not configure a reachable local model endpoint, AI-generation features may be unavailable. Permissions are optional and only requested when the corresponding feature is used.
