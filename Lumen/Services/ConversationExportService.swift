import Foundation

struct ConversationExportService {
    static let currentVersion = 1

    private let encoder: JSONEncoder
    private let iso8601: ISO8601DateFormatter

    init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.iso8601 = formatter
    }

    func exportFile(for conversation: Conversation, format: ConversationExportFormat) throws -> ConversationExportFile {
        let payload = try data(for: conversation, format: format)
        let filename = "\(sanitizedFilename(for: conversation.title)).\(format.fileExtension)"
        return ConversationExportFile(format: format, filename: filename, data: payload)
    }

    func data(for conversation: Conversation, format: ConversationExportFormat) throws -> Data {
        switch format {
        case .json:
            let envelope = ConversationExportEnvelope(
                version: Self.currentVersion,
                exportedAt: Date(),
                conversation: exportedConversation(from: conversation)
            )
            guard let data = try? encoder.encode(envelope) else {
                throw ConversationExportError.encodingFailed(.json)
            }
            return data

        case .markdown:
            guard let data = markdown(for: conversation).data(using: .utf8) else {
                throw ConversationExportError.encodingFailed(.markdown)
            }
            return data
        }
    }

    func markdown(for conversation: Conversation) -> String {
        var lines: [String] = []
        lines.append("# \(conversation.title)")
        lines.append("")
        lines.append("- Export version: \(Self.currentVersion)")
        lines.append("- Conversation ID: \(conversation.id.uuidString)")
        lines.append("- Created: \(iso8601.string(from: conversation.createdAt))")
        lines.append("- Updated: \(iso8601.string(from: conversation.updatedAt))")
        lines.append("- Message count: \(conversation.messages.count)")

        if let model = conversation.model {
            lines.append("- Model: \(model.displayName) (\(model.providerType.displayName))")
        }

        if let prompt = conversation.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty {
            lines.append("")
            lines.append("## System Prompt")
            lines.append("")
            lines.append(prompt)
        }

        lines.append("")
        lines.append("## Messages")

        let exportedMessages = conversation.messages.filter {
            ($0.isUser || $0.isAssistant) && $0.isComplete && !$0.isError
        }
        if exportedMessages.isEmpty {
            lines.append("")
            lines.append("_No completed user or assistant messages to export._")
            return lines.joined(separator: "\n")
        }

        for message in exportedMessages {
            lines.append("")
            lines.append("### \(message.role.displayName)")
            lines.append("")
            lines.append("- Timestamp: \(iso8601.string(from: message.createdAt))")
            if let tokenCount = message.tokenCount {
                lines.append("- Token count: \(tokenCount)")
            }
            if message.hasImages {
                lines.append("- Attachments: \(message.imageData?.count ?? 0) image(s)")
            }
            lines.append("")
            lines.append(message.contentForExport)
        }

        return lines.joined(separator: "\n")
    }

    private func exportedConversation(from conversation: Conversation) -> ExportedConversation {
        ExportedConversation(
            id: conversation.id,
            title: conversation.title,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            isPinned: conversation.isPinned,
            systemPrompt: normalizedSystemPrompt(conversation.systemPrompt),
            model: exportedModel(from: conversation.model),
            messageCount: conversation.messages.count,
            messages: conversation.messages.map(exportedMessage(from:))
        )
    }

    private func exportedModel(from model: AIModel?) -> ExportedConversationModel? {
        guard let model else { return nil }
        return ExportedConversationModel(
            id: model.id,
            name: model.name,
            displayName: model.displayName,
            provider: model.providerType.rawValue,
            supportsImages: model.supportsImages
        )
    }

    private func exportedMessage(from message: ChatMessage) -> ExportedConversationMessage {
        ExportedConversationMessage(
            id: message.id,
            role: message.role.rawValue,
            createdAt: message.createdAt,
            content: message.contentForExport,
            hasImages: message.hasImages,
            imageCount: message.imageData?.count ?? 0,
            isComplete: message.isComplete,
            isError: message.isError,
            tokenCount: message.tokenCount
        )
    }

    private func normalizedSystemPrompt(_ prompt: String?) -> String? {
        let trimmed = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    private func sanitizedFilename(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? "conversation" : trimmed.lowercased()
        var sanitized = ""

        for scalar in source.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                sanitized.unicodeScalars.append(scalar)
            } else {
                sanitized.append("-")
            }
        }

        let collapsed = sanitized
            .replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return collapsed.isEmpty ? "conversation" : collapsed
    }
}

private extension ChatMessage {
    var contentForExport: String {
        isAssistant ? content.stripThinkBlocks() : content
    }
}
