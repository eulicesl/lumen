import Foundation
import UniformTypeIdentifiers
#if canImport(PDFKit)
import PDFKit
#endif

struct ImportedDocument: Identifiable, Hashable, Sendable {
    let id: UUID
    let fileName: String
    let extractedText: String
    let contentTypeIdentifier: String

    init(
        id: UUID = UUID(),
        fileName: String,
        extractedText: String,
        contentTypeIdentifier: String
    ) {
        self.id = id
        self.fileName = fileName
        self.extractedText = extractedText
        self.contentTypeIdentifier = contentTypeIdentifier
    }

    var previewText: String {
        extractedText
            .replacingOccurrences(of: "\n", with: " ")
            .truncatedPreview
    }
}

enum DocumentImportError: LocalizedError {
    case unsupportedFile(String)
    case unreadableFile(String)
    case emptyContent(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile(let fileName):
            return "\(fileName) is not a supported text or PDF document."
        case .unreadableFile(let fileName):
            return "Lumen could not read \(fileName)."
        case .emptyContent(let fileName):
            return "\(fileName) does not contain extractable text."
        }
    }
}

enum DocumentPromptComposer {
    static let maxDocumentCharacters = 12_000
    private static let truncationNote = "\n\n[Document truncated to fit in the chat context.]"

    static func compose(userText: String, documents: [ImportedDocument]) -> String {
        let trimmedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !documents.isEmpty else { return trimmedUserText }

        let blocks = documents
            .map(promptBlock(for:))
            .joined(separator: "\n\n")

        if trimmedUserText.isEmpty {
            return """
            Please use the imported document context below in your response.

            \(blocks)
            """
        }

        return """
        \(trimmedUserText)

        Use the imported document context below in your response.

        \(blocks)
        """
    }

    static func titleSeed(userText: String, documents: [ImportedDocument]) -> String {
        let trimmedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUserText.isEmpty {
            return trimmedUserText
        }

        guard let first = documents.first else { return "" }
        return "Discuss \(first.fileName)"
    }

    static func normalizeExtractedText(_ text: String, maxCharacters: Int = maxDocumentCharacters) -> String {
        let normalizedNewlines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let compacted = collapseExcessBlankLines(in: normalizedNewlines)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard compacted.count > maxCharacters else { return compacted }

        let cutoff = compacted.index(
            compacted.startIndex,
            offsetBy: max(0, maxCharacters - truncationNote.count)
        )
        let truncated = compacted[..<cutoff].trimmingCharacters(in: .whitespacesAndNewlines)
        return truncated + truncationNote
    }

    static func documentSummary(in content: String) -> String {
        let names = documentNames(in: content)
        guard !names.isEmpty else { return content }

        let stripped = content
            .replacingOccurrences(
                of: documentBlockPattern,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let attachmentSummary: String
        if names.count == 1 {
            attachmentSummary = "Attached document: \(names[0])"
        } else {
            let bullets = names.map { "- \($0)" }.joined(separator: "\n")
            attachmentSummary = "Attached documents:\n\(bullets)"
        }

        if stripped.isEmpty {
            return attachmentSummary
        }

        return "\(stripped)\n\n\(attachmentSummary)"
    }

    static func documentNames(in content: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: documentBlockPattern, options: []) else {
            return []
        }

        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        return regex.matches(in: content, options: [], range: range).compactMap { match in
            guard match.numberOfRanges >= 2,
                  let nameRange = Range(match.range(at: 1), in: content) else {
                return nil
            }
            return String(content[nameRange])
        }
    }

    private static let documentBlockPattern = #"\[Document: ([^\n]+)\]\n[\s\S]*?\n\[/Document\]"#

    private static func promptBlock(for document: ImportedDocument) -> String {
        """
        [Document: \(document.fileName)]
        \(document.extractedText)
        [/Document]
        """
    }

    private static func collapseExcessBlankLines(in text: String) -> String {
        var result: [String] = []
        var previousWasBlank = false

        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                if !previousWasBlank {
                    result.append("")
                }
                previousWasBlank = true
            } else {
                result.append(line)
                previousWasBlank = false
            }
        }

        return result.joined(separator: "\n")
    }
}

extension String {
    var documentAwareDisplayText: String {
        DocumentPromptComposer.documentSummary(in: self)
    }
}

actor DocumentImportService {
    static let shared = DocumentImportService()

    static let supportedContentTypes: [UTType] = {
        let candidates: [UTType?] = [
            .pdf,
            .text,
            .plainText,
            .utf8PlainText,
            .commaSeparatedText,
            .json,
            .xml,
            .sourceCode,
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown")
        ]

        var seen = Set<String>()
        return candidates
            .compactMap { $0 }
            .filter { seen.insert($0.identifier).inserted }
    }()

    func importDocument(from url: URL) async throws -> ImportedDocument {
        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
        let contentType = resourceValues?.contentType
        let fileName = resourceValues?.name ?? url.lastPathComponent

        let rawText: String
        if contentType?.conforms(to: .pdf) == true || url.pathExtension.lowercased() == "pdf" {
            rawText = try extractPDFText(from: url, fileName: fileName)
        } else if contentType == nil || supportsTextExtraction(contentType) {
            rawText = try extractTextDocument(from: url, fileName: fileName)
        } else {
            throw DocumentImportError.unsupportedFile(fileName)
        }

        let extractedText = DocumentPromptComposer.normalizeExtractedText(rawText)
        guard !extractedText.isEmpty else {
            throw DocumentImportError.emptyContent(fileName)
        }

        return ImportedDocument(
            fileName: fileName,
            extractedText: extractedText,
            contentTypeIdentifier: contentType?.identifier ?? "public.text"
        )
    }

    private func extractTextDocument(from url: URL, fileName: String) throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DocumentImportError.unreadableFile(fileName)
        }

        let encodings: [String.Encoding] = [.utf8, .unicode, .utf16, .ascii, .isoLatin1]
        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return text
            }
        }

        throw DocumentImportError.unreadableFile(fileName)
    }

    private func extractPDFText(from url: URL, fileName: String) throws -> String {
        #if canImport(PDFKit)
        guard let document = PDFDocument(url: url) else {
            throw DocumentImportError.unreadableFile(fileName)
        }
        return document.string ?? ""
        #else
        throw DocumentImportError.unsupportedFile(fileName)
        #endif
    }

    private func supportsTextExtraction(_ contentType: UTType?) -> Bool {
        guard let contentType else { return true }

        return contentType.conforms(to: .text)
            || contentType.conforms(to: .plainText)
            || contentType.conforms(to: .utf8PlainText)
            || contentType.conforms(to: .sourceCode)
            || contentType.conforms(to: .json)
            || contentType.conforms(to: .xml)
            || contentType.conforms(to: .commaSeparatedText)
    }
}
