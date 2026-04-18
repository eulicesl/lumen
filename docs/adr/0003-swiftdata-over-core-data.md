# 0003: SwiftData over Core Data

- **Status:** Accepted 2025-10-01 (retrospective — decision predates the ADR practice; recorded 2026-04-18)
- **Date:** 2025-10-01
- **Deciders:** Eulices Lopez
- **Related:** [`0002-on-device-first-ai-with-apple-foundation-models.md`](0002-on-device-first-ai-with-apple-foundation-models.md)

## Context

Lumen persists conversations, messages, and memories on-device. The persistence layer is load-bearing: it must be queryable, survive app restarts, and integrate cleanly with SwiftUI. Two first-party options exist: SwiftData (iOS 17+) and Core Data. Third-party options (GRDB, SQLite.swift, Realm) are also available.

## Decision

We will use SwiftData with `@Model` types declared in Swift. Migrations use SwiftData's lightweight migration via `VersionedSchema` and `SchemaMigrationPlan` when schema changes are needed.

## Alternatives considered

- **Core Data** — battle-tested, extensive tooling, NSFetchedResultsController for table views. **Rejected because:** requires `.xcdatamodeld` files and significant boilerplate (NSPersistentContainer, NSManagedObject subclasses); SwiftData eliminates both while targeting the same SQLite backend. The trade-off only inverts if we need fine-grained fetch request customisation that SwiftData's predicate macro cannot express.
- **GRDB** — type-safe SQL, excellent performance, no Apple dependency lock-in. **Rejected because:** adds a third-party dependency to a project that deliberately has zero third-party dependencies; the portability argument is moot when the product is iOS-only.
- **SQLite.swift / raw SQLite** — maximum control and portability. **Rejected because:** requires hand-written schema, migrations, and query builders — maintenance cost is disproportionate for a single-developer project with well-understood domain objects.

## Consequences

- **Positive:** `@Model` classes are plain Swift; no `.xcdatamodeld` drag-and-drop required. SwiftUI `@Query` macro works natively. Automatic CloudKit sync path exists if the product ever wants it.
- **Negative:** SwiftData is iOS 17+; the iOS 26 deployment floor already exceeds this. Lightweight migrations require explicit `VersionedSchema` declarations — easy to forget when iterating quickly, surfacing as runtime crashes on schema changes.
- **Neutral:** The persistent store is still SQLite under the hood; any future escape hatch to GRDB or raw SQLite reads the same file format.

## Revisit trigger

If SwiftData's predicate macro is insufficiently expressive for a required query, or if a SwiftData bug in a shipping iOS version causes data loss, revisit a targeted GRDB adoption for the affected store only.

## References

- WWDC 2023 "Meet SwiftData" and "Model your schema with SwiftData."
- [`Lumen/Stores/`](../../Lumen/Stores/) — all store types that use `@Model` and `@Query`.
