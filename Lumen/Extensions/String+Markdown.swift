import Foundation
import SwiftUI

extension String {
    private static let agentMarkupPrefixes = ["[[TOOL:", "[[RESULT:"]

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

    /// Fast check: returns true only when the string likely contains agent markup.
    var mayContainAgentMarkup: Bool {
        contains("[[TOOL:") || contains("[[RESULT:")
    }

    func stripAgentMarkup(normalizeWhitespace: Bool = true, trimEdges: Bool = true) -> String {
        guard mayContainAgentMarkup else { return self }

        var output = ""
        var index = startIndex

        while index < endIndex {
            if let prefix = Self.agentMarkupPrefixes.first(where: { self[index...].hasPrefix($0) }),
               let closingIndex = agentMarkupClosingIndex(from: index, prefix: prefix) {
                index = closingIndex
                continue
            }

            output.append(self[index])
            index = self.index(after: index)
        }

        if normalizeWhitespace {
            output = output.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        }

        if trimEdges {
            output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return output
    }

    private func agentMarkupClosingIndex(from start: Index, prefix: String) -> Index? {
        var cursor = index(start, offsetBy: prefix.count)
        var bracketDepth = 0

        while cursor < endIndex {
            let current = self[cursor]

            if current == "[" {
                bracketDepth += 1
                cursor = index(after: cursor)
                continue
            }

            if current == "]" {
                let next = index(after: cursor)
                if bracketDepth == 0, next < endIndex, self[next] == "]" {
                    return index(after: next)
                }

                if bracketDepth > 0 {
                    bracketDepth -= 1
                }
            }

            cursor = index(after: cursor)
        }

        return nil
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
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            return try AttributedString(markdown: text, options: options)
        } catch {
            return AttributedString(text)
        }
    }
}
