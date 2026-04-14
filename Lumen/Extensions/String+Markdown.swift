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

    /// True only when the content is control-only tool syntax, not prose that merely mentions it.
    var hasOnlyAgentToolCalls: Bool {
        parsePureAgentToolCalls() != nil
    }

    /// Parses one or more control-only tool calls, allowing bracketed payloads.
    /// Returns nil when the string contains prose or malformed tool-call syntax.
    func parsePureAgentToolCalls() -> [(name: String, input: String)]? {
        var results: [(name: String, input: String)] = []
        var cursor = startIndex

        func skipWhitespace() {
            while cursor < endIndex, self[cursor].isWhitespace {
                cursor = index(after: cursor)
            }
        }

        skipWhitespace()
        while cursor < endIndex {
            let prefix = "[[TOOL:"
            guard self[cursor...].hasPrefix(prefix),
                  let closingIndex = agentMarkupClosingIndex(from: cursor, prefix: prefix) else {
                return nil
            }

            let contentStart = index(cursor, offsetBy: prefix.count)
            let contentEnd = index(closingIndex, offsetBy: -2)
            let inner = self[contentStart..<contentEnd]

            guard let separator = inner.firstIndex(of: "|") else {
                return nil
            }

            let name = inner[..<separator].trimmingCharacters(in: .whitespaces)
            let input = String(inner[index(after: separator)...])
            guard !name.isEmpty else {
                return nil
            }

            results.append((name: name, input: input))
            cursor = closingIndex
            skipWhitespace()
        }

        return results.isEmpty ? nil : results
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
            output = output.collapsingExcessBlankLines()
        }

        if trimEdges {
            output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return output
    }

    private func agentMarkupClosingIndex(from start: Index, prefix: String) -> Index? {
        let contentStart = index(start, offsetBy: prefix.count)

        // Primary: balanced bracket-depth counting. Handles nested groups
        // where the payload itself contains balanced brackets — e.g.
        // [[TOOL:calc|[]]] (payload `[]`), [[TOOL:fetch|see [guide](url)]]
        // (payload contains a markdown link), or [[TOOL:x|[a][b]]]
        // (payload contains multiple balanced groups).
        var cursor = contentStart
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

        // Fallback: the payload contains an unbalanced `[` (for example a
        // regex fragment like `[a-z` or a truncated JSON array), so the
        // balanced scan above never returns to depth 0 and never recognizes
        // the `]]` terminator. Recover by using the first `]]` in the
        // content as the terminator. The TOOL protocol has no escape
        // mechanism for literal `]]` inside a payload, so in that case we
        // can't distinguish a payload-`]]` from the terminator anyway.
        // Best-effort first-`]]` matching is strictly better than silently
        // dropping the tool call.
        if let range = self[contentStart...].range(of: "]]") {
            return range.upperBound
        }

        return nil
    }

    private func collapsingExcessBlankLines() -> String {
        var normalizedLines: [String] = []
        var pendingBlankLines = 0

        enumerateLines { line, _ in
            if line.isEmpty {
                pendingBlankLines += 1
                if pendingBlankLines <= 1 {
                    normalizedLines.append("")
                }
            } else {
                pendingBlankLines = 0
                normalizedLines.append(line)
            }
        }

        if hasSuffix("\n") {
            return normalizedLines.joined(separator: "\n") + "\n"
        }

        return normalizedLines.joined(separator: "\n")
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
