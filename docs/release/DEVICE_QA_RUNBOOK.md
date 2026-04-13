# Lumen Device QA Runbook

Use this runbook on the exact release candidate installed on a physical device.

Record results as `Pass`, `Fail`, or `Needs Follow-Up`.

## Test Context

- Release commit SHA:
- App version:
- Build number:
- Device:
- iOS version:
- Reviewer:
- Date:

## Core Chat Flow

- [ ] Launch app from cold start.
- [ ] Confirm onboarding feels complete and polished.
- [ ] Start a new conversation.
- [ ] Use a starter prompt from the empty state.
- [ ] Send a freeform follow-up message.
- [ ] Wait for the assistant response to complete without UI glitches.
- [ ] Copy a message and confirm copy feedback appears.
- [ ] Long-press a user message and verify `Edit & Resend`.
- [ ] Long-press the latest assistant message and verify regenerate-related actions.
- [ ] Save a useful assistant message to memory.

## Search and History

- [ ] Open history and confirm recent conversations are visible and legible.
- [ ] Use search to find a previous message.
- [ ] Open a search result and confirm the app jumps to the correct message.
- [ ] Pull to refresh conversation history and confirm state remains stable.

## Provider and Model UX

- [ ] Verify the header provider chip is visible, minimal, and tappable.
- [ ] Open the model picker from the chip.
- [ ] Confirm Apple Intelligence, Ollama Local, and Ollama Cloud are presented clearly.
- [ ] Confirm the app remains useful when Ollama providers are disabled.
- [ ] If available, enable Ollama Local and confirm settings copy and status make sense.
- [ ] If available, enable Ollama Cloud and confirm key entry and status make sense.

## Documents and Attachments

- [ ] Import a supported document.
- [ ] Confirm the document chip appears in the composer.
- [ ] Send a document-grounded prompt.
- [ ] Confirm the response references the imported document context appropriately.
- [ ] Remove a pending document and confirm the chip disappears cleanly.

## Settings, Privacy, and Support

- [ ] Open Settings from the app shell.
- [ ] Confirm active model summary is accurate.
- [ ] Confirm provider status sections read clearly and do not feel like debug UI.
- [ ] Open Privacy and confirm copy matches shipped behavior.
- [ ] Open Support and confirm the URL/content is reachable and accurate.

## Accessibility and Dynamic Type

- [ ] Verify at default text size.
- [ ] Verify at a larger standard Dynamic Type size.
- [ ] Verify at an accessibility text size.
- [ ] Confirm message bubbles, composer, settings rows, and search rows remain usable.
- [ ] Run a VoiceOver pass on the main path.
- [ ] Confirm high-frequency actions have correct labels, values, and hints.
- [ ] Confirm Reduce Motion settings suppress nonessential motion cleanly.

## Visual Design / HIG Checks

- [ ] Verify light mode.
- [ ] Verify dark mode.
- [ ] Confirm the app feels coherent on iPhone.
- [ ] Confirm the app feels coherent on iPad if iPad distribution remains enabled.
- [ ] Confirm the UI does not show placeholder, debug, or internal-facing content.
- [ ] Confirm toolbar chrome feels restrained and native.
- [ ] Confirm Liquid Glass usage is subtle and appropriate.

## App Review Risk Checks

- [ ] The app remains useful on the reviewer path without custom credentials.
- [ ] Apple Intelligence-only path is understandable and functional on supported hardware.
- [ ] Optional Ollama setup does not block normal app understanding.
- [ ] All error states have a clear recovery path.
- [ ] No screen suggests the app is incomplete or requires unavailable internal setup.

## Final Signoff

- [ ] No crash, dead-end, or broken state found.
- [ ] No App Review-blocking issue found.
- [ ] Any failures above are linked to a fixing PR before submission.
