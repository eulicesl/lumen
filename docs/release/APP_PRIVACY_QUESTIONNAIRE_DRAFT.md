# Lumen App Privacy Questionnaire

Final answer set for the **App Privacy** section in App Store Connect for Lumen v1.0 (build 1).

Verify each answer against the exact release binary before submitting. If a new SDK, a new network call, or a new data-handling path is added after this document was written, re-audit this file in the same PR.

---

## Summary

| Section | Answer |
|---|---|
| Does your app collect data from this app? | **Yes** (conditional — only when the user enables Ollama Cloud) |
| Used to track users? | **No** |
| Linked to the user? | **Yes** (the Ollama Cloud API key is user-specific) |
| Third-party analytics SDK? | **No** |
| Third-party advertising SDK? | **No** |

## Rationale

Lumen does not run a developer-operated backend, analytics pipeline, crash-reporting service, or ad-tech collection path. All conversation content, preferences, and memories are stored locally on the device using platform-standard storage.

Lumen's **default reviewer path uses Apple Intelligence, which runs fully on-device**. No content leaves the device on that path.

Lumen ships an **optional Ollama Cloud provider** that the user can enable in Settings. When enabled, the provider authenticates to `https://ollama.com` using an API key the user supplies, and chat messages (plus any attached image or document content) are sent to `https://ollama.com/api/chat` for inference. Because the app is the vehicle for that transmission — even though the endpoint is the user's own Ollama Cloud account and Lumen operates no backend — Apple's App Privacy disclosure rules treat this as data collection that must be disclosed.

Lumen also supports an **Ollama Local provider** where the user supplies a URL for a server on their own network. Because that endpoint is the user's own infrastructure and not addressable over the open internet, it does not change the App Store Connect disclosure beyond what Ollama Cloud already requires.

`Lumen/Resources/PrivacyInfo.xcprivacy` declares `NSPrivacyCollectedDataTypes` empty and `NSPrivacyTracking` false because the privacy manifest captures what the developer collects, which is still nothing. The App Store Connect questionnaire is broader and asks about data transmitted from the app for any purpose, so the two documents can differ in answer shape even though they describe the same behavior.

---

## Per-category answers

### User Content — **Yes**

- Subcategory: **Other User Content** (covers chat messages and imported documents).
- Add **Photos or Videos** only if the image-attachment feature is enabled in the release binary and those images can be sent to Ollama Cloud.
- Linked to user identity: **Yes** — the Ollama Cloud API key is user-specific; requests the app makes on the user's behalf are linked to that account.
- Used for tracking: **No**.
- Purposes: **App Functionality** (the user enabled Ollama Cloud specifically to route inference through it).
- Reviewer-facing note: only collected when the user enables the optional Ollama Cloud provider. The default Apple Intelligence path keeps content on-device.

### Everything else — **No**

- Contact Info: **No**
- Health and Fitness: **No**
- Financial Info: **No**
- Location: **No**
- Sensitive Info: **No**
- Contacts: **No**
- Browsing History: **No**
- Search History: **No** (search terms are executed locally against on-device conversation history, not transmitted)
- Identifiers: **No** (no user ID, device ID, or advertising ID is sent; the Ollama Cloud API key is not asked about in this section)
- Purchases: **No**
- Usage Data: **No** (no analytics collection)
- Diagnostics: **No** (no third-party diagnostics collection)
- Other Data: **No**

---

## Required API access (declared in PrivacyInfo.xcprivacy)

These are API-usage reason declarations, not data-collection disclosures. App Store Connect treats them separately from the privacy questionnaire. Match this list against `Lumen/Resources/PrivacyInfo.xcprivacy` whenever you change SwiftData or storage behavior.

- `NSPrivacyAccessedAPICategoryUserDefaults` — reason `CA92.1` (access info from same-app group containers, limited to own app). Used for settings storage.
- `NSPrivacyAccessedAPICategoryFileTimestamp` — reason `3B52.1` (access file timestamps within the app's own container/sandbox). Used by SwiftData for the conversation store.
- `NSPrivacyAccessedAPICategoryDiskSpace` — reason `E174.1` (display storage info to the user, or prevent exceeding storage limits). Used by SwiftData when checking available storage before writing.

If additional required-reason APIs are introduced (system boot time, active keyboards, etc.), add them to `PrivacyInfo.xcprivacy` with the correct reason code and re-verify this file.

---

## Permissions declared in Info.plist

Permissions are orthogonal to the privacy questionnaire but the user sees them both, so they should be consistent.

| Key | Purpose | Status |
|---|---|---|
| `NSMicrophoneUsageDescription` | Voice input for dictation | **Declared**, matches shipping feature |
| `NSSpeechRecognitionUsageDescription` | On-device speech-to-text for voice input | **Declared**, matches shipping feature |
| `NSCameraUsageDescription` | If camera capture is enabled in the shipped build | **Verify before submission** — only declare if the feature ships |
| `NSPhotoLibraryUsageDescription` | If photo selection is enabled in the shipped build | **Verify before submission** — only declare if the feature ships |

---

## Pre-submission verification

- [ ] `PrivacyInfo.xcprivacy` in the release binary still declares zero collected data types and `NSPrivacyTracking=false`.
- [ ] The three API reason declarations above (`UserDefaults` / `FileTimestamp` / `DiskSpace`) are still present and still match the code paths that use them.
- [ ] No new networking SDK, analytics SDK, or crash reporter has been added since this document was written.
- [ ] If the image-attachment feature is shipped and images can be sent to Ollama Cloud, the App Store Connect User Content subcategory includes **Photos or Videos**.
- [ ] `Info.plist` permission strings match the exact permission prompts in the release build. Permissions that do not ship must not have a usage description.
- [ ] App Store Connect answers match this document section-by-section.
- [ ] Privacy Policy URL resolves and the linked page explicitly mentions the opt-in Ollama Cloud transmission described above.
