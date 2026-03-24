import Foundation
import SwiftUI

extension String {
    var hasMarkdown: Bool {
        contains("**") || contains("*") || contains("# ") ||
        contains("```") || contains("`") || contains("- ") ||
        contains("[") || contains("| ")
    }

    var hasCodeBlocks: Bool {
        contains("```")
    }

    var hasThinkBlock: Bool {
        contains("<think>")
    }

    func stripThinkBlocks() -> String {
        guard hasThinkBlock else { return self }
        var result = self
        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound...end.upperBound)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractThinkBlocks() -> [String] {
        var blocks: [String] = []
        var searchRange = startIndex..<endIndex
        while let start = range(of: "<think>", range: searchRange),
              let end = range(of: "</think>", range: start.upperBound..<endIndex) {
            let content = String(self[start.upperBound..<end.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                blocks.append(content)
            }
            searchRange = end.upperBound..<endIndex
        }
        return blocks
    }

    var truncatedPreview: String {
        let limit = 120
        if count <= limit { return self }
        return String(prefix(limit)) + "…"
    }

    func codeLanguage(from block: String) -> String? {
        let lines = block.components(separatedBy: "\n")
        guard let firstLine = lines.first,
              firstLine.hasPrefix("```") else { return nil }
        let lang = firstLine.dropFirst(3).trimmingCharacters(in: .whitespaces)
        return lang.isEmpty ? nil : lang
    }
}

extension AttributedString {
    static func fromMarkdown(_ text: String) -> AttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlinesOnlyPreservingWhitespace
            return try AttributedString(markdown: text, options: options)
        } catch {
            return AttributedString(text)
        }
    }
}
