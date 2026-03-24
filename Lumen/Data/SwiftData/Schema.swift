import SwiftData
import Foundation

enum LumenSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ConversationSD.self, MessageSD.self, AIModelSD.self]
    }
}

enum LumenMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LumenSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

extension Schema {
    static var lumen: Schema {
        Schema(
            [ConversationSD.self, MessageSD.self, AIModelSD.self],
            version: .init(1, 0, 0)
        )
    }
}
