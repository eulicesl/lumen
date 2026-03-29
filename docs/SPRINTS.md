# Lumen Sprint Plan

This file translates the roadmap into ordered implementation sprints.

## Sprint 0 — Foundation / Control Plane
Goal:
- establish product and execution system

Included:
- PRD / DESIGN / ROADMAP
- micro-PRDs
- repo instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`)
- `.ralphy/config.yaml`

## Sprint 1 — App Store Foundations
### 001 Settings unification
**Owner:** solo

### 002 Export conversations
**Owner:** parallel-safe

### 003 Permission hardening
**Owner:** parallel-safe

Parallelization:
- 001 solo
- 002 and 003 may run in parallel

## Sprint 2 — Quality and Trust
### 004 Accessibility pass
### 005 UI smoke tests
### 006 Product/support/privacy surface

Parallelization:
- 004, 005, and 006 can partially run in parallel if they do not collide on the same views/files

## Sprint 3 — Product Maturity
### 007 Conversation tags + lightweight filters
### 008 Import / restore

## Sprint 4 — Architecture and Differentiation
### 009 Provider/tool architecture cleanup
### 010 Foundation Models-native enhancements

## Sprint 5 — Premium Polish
### 011 Demo mode / sample prompts / empty-state polish
### 012 Composer/input modernization
### 013 Optional advanced iOS 26 shell polish

## Review Rules
- one task branch per micro-PRD
- one concern per PR
- use draft PRs when validation is incomplete
- shared shell/settings/provider work should not be parallelized casually
- upstream-facing work should be deliberate and clean
