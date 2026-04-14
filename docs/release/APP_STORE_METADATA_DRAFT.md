# Lumen App Store Metadata

Final copy for the App Store Connect listing for Lumen v1.0 (build 1). Character budgets are noted next to each field so copy-edits stay inside App Store Connect's limits without a round-trip.

Verify each field in App Store Connect before submitting. Light localizations can be added post-launch; this document covers the primary English (US) listing only.

---

## App identity

- **App Name:** `Lumen` — 5/30 characters.
- **Subtitle:** `Private local AI assistant` — 26/30 characters.
- **Primary category:** Productivity.
- **Secondary category:** Utilities.

### Category rationale

"Utilities" is a better fit than the earlier draft's "Developer Tools" — Lumen is a consumer utility for on-device AI chat, not a developer-facing tool. Developer Tools would likely trigger App Review questions about the target audience, and Utilities reinforces the privacy-first native-app positioning.

---

## Promotional text

**Budget:** 170 characters. Promotional text can be updated without resubmitting a binary, so use this field for the current positioning message.

> Private AI on your device first. Start with Apple Intelligence, or connect Ollama. Search history, import documents, keep your data yours.

139/170 characters.

---

## Description

**Budget:** 4000 characters.

> Lumen is a privacy-first AI assistant for iPhone and iPad.
>
> Use Apple Intelligence on supported hardware with no account, no login, and no third-party setup. Or optionally connect your own Ollama server on your local network or your own Ollama Cloud account. Your conversations stay on your device or inside your own environment instead of being routed through a developer-operated cloud.
>
> What you can do with Lumen:
>
> • Chat with on-device or local AI models
> • Switch between Apple Intelligence and Ollama in one tap
> • Search and jump through your full conversation history
> • Edit any prompt and retry without losing context
> • Import documents for local context in a conversation
> • Attach images for quick analysis
> • Use voice input with on-device speech recognition
> • Save key memories for future chats
> • Run small built-in tools inside a conversation
>
> Lumen is designed as a real native product, not a wrapper around a web app. It is built for SwiftUI on iOS 26 and iPadOS 26, supports Dynamic Type and accessibility across core surfaces, and respects Reduce Motion.
>
> Privacy by design: Lumen does not run a developer-operated backend. There is no analytics pipeline, no advertising SDK, and no tracking. If you choose to use Ollama, requests go to the server you configured, not to the Lumen developer.

~1,220/4,000 characters — room to add testimonials or use cases in a later update.

---

## Keywords

**Budget:** 100 characters total, comma-separated, no spaces between entries. Avoid repeating words already in the app name or subtitle.

> `chatbot,documents,memory,voice,image,history,search,productivity,ollama,offline,on device`

91/100 characters.

### Why each keyword is included

- `chatbot`, `ollama`, `offline`, `on device` — core discovery terms for the category and differentiator.
- `documents`, `image`, `voice`, `memory`, `history`, `search` — feature-surface terms that match what the app actually does.
- `productivity` — secondary-category reinforcement.

### Deliberately excluded

- `AI`, `assistant`, `private`, `local` — already present in the app name's field (via subtitle); App Store indexes name + subtitle + keywords together, so repeats waste budget.

---

## Support and marketing URLs

- **Support URL:** required. Must point to a page where a user can reach you for help. Set this to the Lumen support page before submission.
- **Marketing URL:** optional. If set, point to the product landing page.
- **Privacy Policy URL:** required. Must point to the published privacy policy.

---

## Age rating

- Target: **4+**.
- Violations to check against before submitting: no unrestricted web content (Lumen does not browse the open web); no user-generated content shared to other users (all content stays with the author); no gambling, no alcohol/drug/tobacco references.
- Note for App Review: Ollama responses can in principle include any content the user's chosen model produces. This is the same posture as any LLM-based app; the rating stays 4+ because Lumen itself does not generate or host such content and there is no social/UGC surface.

---

## What's New in This Version (v1.0)

**Budget:** 4000 characters.

> Welcome to Lumen. This is the first release.
>
> • Private AI chat using Apple Intelligence on supported devices — no account required.
> • Optional Ollama Local and Ollama Cloud providers for users who want to bring their own model endpoint.
> • Import documents, attach images, and use voice input for fast input.
> • Search and jump through conversation history, edit prompts and retry without losing context.
> • Save memories from a conversation to reuse in future chats.
> • Native SwiftUI experience built for iOS 26 and iPadOS 26, with Dynamic Type and accessibility across core surfaces.
>
> Thanks for trying Lumen.

---

## Pre-submission verification

- [ ] App name in App Store Connect matches Xcode `CFBundleName` (`Lumen`).
- [ ] Subtitle is 30 characters or fewer.
- [ ] Promotional text is 170 characters or fewer.
- [ ] Keywords total is 100 characters or fewer, no spaces between entries.
- [ ] Description only describes features shipped in the exact release candidate.
- [ ] "What's New" text is written in marketing voice, not changelog shorthand.
- [ ] Support URL, Marketing URL, and Privacy Policy URL all resolve.
- [ ] Age rating questionnaire completed and matches 4+.
- [ ] Primary and secondary categories are set.
- [ ] Screenshots uploaded for the required iPhone and iPad sizes, sourced from the polished release-candidate capture pass.
