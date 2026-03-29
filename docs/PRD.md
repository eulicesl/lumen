# Lumen Product Requirements Document (PRD)

## Product
Lumen is a privacy-first, local-first AI assistant for Apple platforms that uses on-device Apple Intelligence and local-network Ollama models without requiring a cloud account.

## Product Goal
Ship a professional, trustworthy, App Store-ready assistant that feels deeply native on iPhone, showcases strong engineering and product judgment, and demonstrates a clear point of view: useful AI should be private, fast, and local by default.

## Why Lumen Exists
Most AI assistants optimize for cloud lock-in, provider dependency, and generic chat UX. Lumen should stand apart by offering:
- local-first AI usage
- privacy by default
- a polished Apple-native experience
- practical assistant features instead of gimmicks
- a portfolio-quality example of modern SwiftUI and systems thinking

## Target Users
### Primary
- privacy-conscious iPhone users
- technically curious users who want Apple Intelligence and/or local Ollama access
- users who want a personal assistant without cloud-account dependency

### Secondary
- developers, recruiters, and hiring managers evaluating product/engineering quality
- power users who want a local AI assistant with extensibility

## Product Principles
1. **Privacy first** — user data stays on-device or on the local network whenever possible.
2. **Native by default** — use Apple platform patterns before inventing custom UX.
3. **Fast and trustworthy** — reliability and clarity matter more than feature count.
4. **Opinionated over bloated** — do not become a kitchen-sink AI shell.
5. **Portfolio-worthy execution** — every shipped feature should reinforce engineering credibility.
6. **App Store realism** — permissions, documentation, polish, and review-readiness are part of the product.

## Core Jobs To Be Done
- chat privately with local/on-device AI models
- switch between Apple Intelligence and Ollama models easily
- use voice and image input naturally
- search and revisit prior conversations
- save prompts and reuse them efficiently
- preserve user trust through export, privacy clarity, and reliable settings

## Current Strengths
- SwiftUI native app architecture
- Apple Intelligence + Ollama support
- onboarding
- memory and prompt library primitives
- widgets and App Intents
- privacy manifest and release scaffolding

## App Store 1.0 Success Criteria
Lumen 1.0 is ready when it satisfies all of the following:
- coherent settings architecture
- polished onboarding and chat shell
- clear privacy and support surfaces
- export capability for user conversations
- permission-denial UX is graceful and recoverable
- accessibility pass is complete enough for serious use
- core app flows are tested and release-checked
- screenshots/demo assets make the app legible as a product

## Non-Goals for 1.0
- feature parity with Enchanted
- cross-platform sprawl
- desktop-first advanced workflows
- large cloud-provider expansion beyond the current local-first story
- feature-flag-heavy experimental sprawl

## Strategic Differentiation
Lumen should remain distinct from Enchanted by leaning into:
- local-first trust
- Apple-native polish
- a simpler, more opinionated product story
- iPhone-first practicality

## Risks
- product drift from multiple settings surfaces
- too much feature-porting from Enchanted without preserving Lumen identity
- underinvesting in trust features like export/support/privacy
- overinvesting in novelty before App Store fundamentals are solid

## Release Priorities
### Must-Have Before App Store
- unified settings architecture
- export capability
- permission/App Review hardening
- accessibility pass
- stronger test/release confidence
- product/support documentation and assets

### High-Value Next
- tags and lightweight filtering for conversations
- provider/tooling architecture cleanup
- more native Foundation Models features
- import/restore
- presentation and demo polish
