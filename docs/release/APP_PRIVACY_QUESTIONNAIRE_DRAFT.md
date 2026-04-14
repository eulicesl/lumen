# Lumen App Privacy Questionnaire

Final answer set for the **App Privacy** section in App Store Connect for Lumen v1.0 (build 1).

Verify each answer against the exact release binary before submitting. If a new SDK, a new network call, or a new data-handling path is added after this document was written, re-audit this file in the same PR.

---

## Summary

| Section | Answer |
|---|---|
| Does your app collect data from this app? | **No** |
| Used to track users? | **No** |
| Linked to the user? | N/A |
| Third-party analytics SDK? | **No** |
| Third-party advertising SDK? | **No** |

## Rationale

Lumen does not run a developer-operated backend, analytics pipeline, crash-reporting service, or ad-tech collection path. All conversation content, preferences, and memories are stored locally on the device using platform-standard storage.

When the user explicitly configures an Ollama Local or Ollama Cloud provider, app content is sent to the server URL or hosted account the user entered. That endpoint is operated by the user (or Ollama), not by the Lumen developer, so it is not "data collection by this app's developer" under App Store Connect's definition. The user is in direct control of that endpoint and can change or remove it at any time.

This matches what `Lumen/Resources/PrivacyInfo.xcprivacy` declares at build time:

- `NSPrivacyCollectedDataTypes` is empty.
- `NSPrivacyTracking` is `false`.
- `NSPrivacyTrackingDomains` is empty.

---

## Per-category answers

For every data-type category in the App Store Connect questionnaire, the answer is **No** for the shipped app.

- Contact Info: **No**
- Health and Fitness: **No**
- Financial Info: **No**
- Location: **No**
- Sensitive Info: **No**
- Contacts: **No**
- User Content: **No**
   - The developer does not collect user content. When the user configures an Ollama provider, user content is sent to the user's chosen endpoint; App Store Connect asks about developer-side collection, so this remains "No."
- Browsing History: **No**
- Search History: **No**
   - Search terms stay on-device; see User Content note above.
- Identifiers: **No**
- Purchases: **No**
- Usage Data: **No**
- Diagnostics: **No**
- Other Data: **No**

---

## Required API access (already declared in PrivacyInfo.xcprivacy)

These are API-usage reason declarations, not data-collection disclosures. App Store Connect treats them separately from the privacy questionnaire.

- `NSPrivacyAccessedAPICategoryUserDefaults` — reason `CA92.1` (access info from same-app group containers, limited to own app). Used for settings storage.

If additional required-reason APIs are introduced (file timestamps, system boot time, disk space, active keyboards), add them to `PrivacyInfo.xcprivacy` with the correct reason code and re-verify this file.

---

## Permissions declared in Info.plist

Permissions are orthogonal to the privacy questionnaire but the user sees them both, so they should be consistent.

| Key | Purpose | Status |
|---|---|---|
| `NSMicrophoneUsageDescription` | Voice input for dictation | **Declared**, matches shipping feature |
| `NSSpeechRecognitionUsageDescription` | On-device speech-to-text for voice input | **Declared**, matches shipping feature |
| `NSCameraUsageDescription` | If camera capture is enabled in the shipped build | **Verify before submission** — only declare if the feature ships |
| Photo Library (`NSPhotoLibraryUsageDescription` or add/only `NSPhotoLibraryAddUsageDescription`) | If photo selection is enabled in the shipped build | **Verify before submission** — only declare if the feature ships |

---

## Pre-submission verification

- [ ] `PrivacyInfo.xcprivacy` in the release binary still declares zero collected data types and `NSPrivacyTracking=false`.
- [ ] No new networking SDK, analytics SDK, or crash reporter has been added since this document was written.
- [ ] `Info.plist` permission strings match the exact permission prompts in the release build. Permissions that do not ship must not have a usage description (Apple rejects usage strings for unused entitlements).
- [ ] App Store Connect answers match this document section-by-section.
- [ ] Privacy Policy URL resolves and the content of the linked page matches the answers above.
