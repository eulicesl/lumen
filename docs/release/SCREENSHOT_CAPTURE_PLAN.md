# Lumen Screenshot Capture Plan

This document translates the App Store screenshot requirement into a repeatable capture plan for Lumen.

## Current Apple requirement

As of the current Apple documentation, one to ten screenshots are allowed per required device class.
For iPhone, providing 6.9-inch screenshots satisfies the required iPhone set.
For iPad, providing 13-inch screenshots satisfies the required iPad set.

Apple references:

- Screenshot specs: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- Upload guidance: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots

## Required targets for Lumen

- iPhone: 6.9-inch screenshots
- iPad: 13-inch screenshots, if iPad distribution remains enabled

## Suggested screenshot set

### iPhone

1. Chat screen with local AI response in progress
2. Search over conversation history
3. Document import and context-aware chat
4. Voice input / dictation
5. Memory and settings / privacy positioning

### iPad

1. Split-view conversation layout
2. Search or history view with larger-screen context
3. Settings / privacy or model configuration

## Capture rules

- Capture only shipped behavior from the release candidate
- Prefer clean, realistic prompts and outputs
- Avoid placeholder copy
- Keep status bar, battery, and time presentation consistent
- Use the same visual language across the full screenshot set

## Device sizes from Apple reference

- iPhone 6.9-inch accepted sizes include:
  - 1290 x 2796 portrait
  - 2796 x 1290 landscape
  - 1320 x 2868 portrait
  - 2868 x 1320 landscape
- iPad 13-inch accepted sizes include:
  - 2064 x 2752 portrait
  - 2752 x 2064 landscape
  - 2048 x 2732 portrait
  - 2732 x 2048 landscape

## Output organization

Store the final captured assets outside the source tree or in a dedicated release-assets folder that is not confused with runtime app resources.
