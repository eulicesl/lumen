# Lumen App Privacy Questionnaire Draft

This document is a working draft for the App Privacy section in App Store Connect.
Final answers must be verified against the release binary before submission.

## High-level expectation

- Data collection by the developer: No user data collected for tracking or analytics in the shipped app
- Tracking: No
- Third-party advertising SDKs: No

## Data types

Expected current answer set for the shipped product:

- Contact Info: No
- Health and Fitness: No
- Financial Info: No
- Location: No
- Sensitive Info: No
- Contacts: No
- User Content: No developer-side collection; user content may be sent to a user-configured local or self-hosted model endpoint
- Browsing History: No
- Search History: No developer-side collection; search terms remain local unless the user routes requests to a user-configured model endpoint
- Identifiers: No
- Purchases: No
- Usage Data: No analytics collection
- Diagnostics: No third-party diagnostics collection

## Why this draft says "No developer-side collection"

Lumen stores conversation and preference data locally on-device for app functionality, but the shipped app does not include a developer-operated cloud backend, analytics pipeline, or ad-tech collection path.
When the user configures Ollama, app content may be sent to a user-provided or self-hosted endpoint on the user's local network rather than to infrastructure operated by the developer.

## Permissions to verify against the release binary

The following permissions are currently declared in `Lumen/Resources/Info.plist` and should be verified against the release build:

- Microphone (`NSMicrophoneUsageDescription`)
- Speech Recognition (`NSSpeechRecognitionUsageDescription`)

The following user-facing capabilities exist in the app and should be verified before final submission:

- Camera: add and verify `NSCameraUsageDescription` if camera capture remains enabled
- Photo Library: add and verify the appropriate photo-library usage description if photo selection remains enabled
- Files / document import: verify final document-picker behavior and any required entitlements or reviewer-facing notes

## Final verification steps

- compare this draft against `Lumen/Resources/PrivacyInfo.xcprivacy`
- compare this draft against the exact permission prompts in the release build
- compare this draft against the final `Lumen/Resources/Info.plist` permission strings
- verify no new SDK or network path was added after this document was written
