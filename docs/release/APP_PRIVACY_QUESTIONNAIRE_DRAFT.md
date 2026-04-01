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
- User Content: No developer-side collection
- Browsing History: No
- Search History: No developer-side collection
- Identifiers: No
- Purchases: No
- Usage Data: No analytics collection
- Diagnostics: No third-party diagnostics collection

## Why this draft says "No developer-side collection"

Lumen stores conversation and preference data locally on-device for app functionality, but the shipped app does not include a developer-operated cloud backend, analytics pipeline, or ad-tech collection path.

## Permissions to verify against the release binary

- Microphone
- Speech Recognition
- Camera
- Photo Library
- Files / document import

## Final verification steps

- compare this draft against `Lumen/Resources/PrivacyInfo.xcprivacy`
- compare this draft against the exact permission prompts in the release build
- verify no new SDK or network path was added after this document was written
