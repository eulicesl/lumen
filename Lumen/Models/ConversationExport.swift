import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct ConversationExportFile: Transferable {
    let format: ConversationExportFormat
    let filename: String
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            guard export.format == .json else {
                throw ConversationExportError.unsupportedTransferType(.json)
            }
            return export.data
        }

        DataRepresentation(exportedContentType: .markdown) { export in
            guard export.format == .markdown else {
                throw ConversationExportError.unsupportedTransferType(.markdown)
            }
            return export.data
        }
    }
}

enum ConversationExportFormat: String, CaseIterable, Identifiable, Sendable {
    case json
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .json: "Export JSON"
        case .markdown: "Export Markdown"
        }
    }

    var utType: UTType {
        switch self {
        case .json: .json
        case .markdown: .markdown
        }
    }

    var fileExtension: String {
        switch self {
        case .json: "json"
        case .markdown: "md"
        }
    }

    var iconName: String {
        switch self {
        case .json: "curlybraces"
        case .markdown: "doc.plaintext"
        }
    }
}

struct ConversationExportEnvelope: Codable, Sendable {
    let version: Int
    let exportedAt: Date
    let conversation: ExportedConversation
}

struct ExportedConversation: Codable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let isPinned: Bool
    let systemPrompt: String?
    let model: ExportedConversationModel?
    let messageCount: Int
    let messages: [ExportedConversationMessage]
}

struct ExportedConversationModel: Codable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let provider: String
    let supportsImages: Bool
}

struct ExportedConversationMessage: Codable, Sendable {
    let id: UUID
    let role: String
    let createdAt: Date
    let content: String
    let hasImages: Bool
    let imageCount: Int
    let isComplete: Bool
    let isError: Bool
    let tokenCount: Int?
}

enum ConversationExportError: LocalizedError {
    case unsupportedTransferType(ConversationExportFormat)
    case encodingFailed(ConversationExportFormat)

    var errorDescription: String? {
        switch self {
        case .unsupportedTransferType(let format):
            return "Unsupported export transfer type: \(format.rawValue)"
        case .encodingFailed(let format):
            return "Failed to encode conversation as \(format.rawValue)."
        }
    }
}
