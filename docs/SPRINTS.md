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
Machine-readable task source:
- `tasks/sprint-1.yaml`

### 001 Settings unification
**Owner:** solo
**Task file title:** `settings-unification`

### 002 Export conversations
**Owner:** parallel-safe
**Task file title:** `export-conversations`

### 003 Permission hardening
**Owner:** parallel-safe
**Task file title:** `permission-hardening`

Parallelization:
- `parallel_group: 1` => settings unification runs first
- `parallel_group: 2` => export conversations and permission hardening may run together

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
