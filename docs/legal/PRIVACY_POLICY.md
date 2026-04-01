# Lumen Privacy Policy

Last updated: 2026-03-31

## Summary

Lumen is designed as a privacy-first native app.
The shipped product does not require an account, does not include analytics, and does not route conversation data through a vendor-hosted cloud backend.

## Data Lumen stores

Lumen stores the following information locally on your device:

- conversations and message history
- optional memory entries you save for cross-conversation context
- app preferences and local model configuration
- imported document text used to support a conversation

This data is stored using Apple platform storage APIs such as SwiftData and UserDefaults.

## AI processing

Lumen supports local inference paths:

- Apple Intelligence / Foundation Models on supported devices
- Ollama running on the same device or local network

When you use Ollama, requests are sent only to the Ollama server you configured.
In the intended product setup, that server is local to your device or your network rather than a vendor-hosted cloud API.

## Permissions

Lumen may request access to:

- Microphone, for voice input you explicitly start
- Speech Recognition, to transcribe your voice input on-device
- Camera or Photo Library, when you choose to attach an image
- Files, when you choose to import a document
- Spotlight indexing, to make local conversation discovery and launch faster

Permissions are optional and used only for the feature you invoke.

## Data sharing

Lumen does not sell personal data.
Lumen does not use advertising SDKs or third-party analytics in the shipped app.

If you configure Lumen to talk to a service outside your device or local network, you are responsible for that service's privacy and security posture.

## Contact

Support and privacy requests should be routed through the public support page for the release build:

- https://eulicesl.github.io/lumen/support/
