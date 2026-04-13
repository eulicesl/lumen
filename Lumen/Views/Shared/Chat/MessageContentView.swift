import SwiftUI
import Foundation

// MARK: - Content segment model

enum ContentSegment: Identifiable {
    case text(String)
    case code(language: String, body: String)

    var id: String {
        switch self {
        case .text(let s):           return "t:\(s.hashValue)"
        case .code(let l, let b):    return "c:\(l):\(b.hashValue)"
        }
    }
}

// MARK: - View

/// Renders a mixed text+code message. Text segments are plain body text;
/// code segments are rendered in full-width dark `CodeBlockView` panels.
/// Used for assistant messages that contain fenced code blocks.
struct MessageContentView: View {
    let text: String
    let maxWidth: CGFloat

    private var segments: [ContentSegment] { Self.parseSegments(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.sm) {
            ForEach(segments) { segment in
                switch segment {
                case .text(let str):
                    let trimmed = str.trimmingCharacters(in: .init(charactersIn: "\n"))
                    if !trimmed.isEmpty {
                        Text(AttributedString.fromMarkdown(trimmed))
                            .font(LumenType.messageBody)
                            .foregroundStyle(Color.primary)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .frame(maxWidth: maxWidth, alignment: .leading)
                    }
                case .code(let lang, let body):
                    CodeBlockView(language: lang, code: body)
                        .frame(maxWidth: maxWidth)
                }
            }
        }
    }

    // MARK: - Segment parser

    static func parseSegments(_ text: String) -> [ContentSegment] {
        var segments: [ContentSegment] = []

        // Pattern: opening fence (``` + optional language + newline),
        //          captured code body (non-greedy), closing fence (```)
        guard let regex = try? NSRegularExpression(
            pattern: #"```([a-zA-Z0-9+#\-]*)\n([\s\S]*?)```"#,
            options: []
        ) else {
            return [.text(text)]
        }

        var lastEnd = text.startIndex
        let nsRange = NSRange(text.startIndex..., in: text)

        regex.enumerateMatches(in: text, options: [], range: nsRange) { match, _, _ in
            guard let match,
                  let fullRange  = Range(match.range, in: text) else { return }

            let before = String(text[lastEnd..<fullRange.lowerBound])
            if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.text(before))
            }

            let lang = match.numberOfRanges > 1
                ? (Range(match.range(at: 1), in: text).map { String(text[$0]) } ?? "")
                : ""

            let body = match.numberOfRanges > 2
                ? (Range(match.range(at: 2), in: text).map {
                    String(text[$0]).trimmingCharacters(in: .init(charactersIn: "\n"))
                } ?? "")
                : ""

            segments.append(.code(language: lang, body: body))
            lastEnd = fullRange.upperBound
        }

        let tail = String(text[lastEnd...])
        if !tail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            segments.append(.text(tail))
        }

        return segments.isEmpty ? [.text(text)] : segments
    }
}

#Preview {
    ScrollView {
        MessageContentView(
            text: """
            Here's a simple Swift example:

            ```swift
            struct ContentView: View {
                @State private var count = 0
                var body: some View {
                    Button("Count: \\(count)") { count += 1 }
                }
            }
            ```

            And here's the Python equivalent:

            ```python
            count = 0
            def increment():
                global count
                count += 1
            ```

            Both are equivalent in functionality.
            """,
            maxWidth: 600
        )
        .padding()
    }
}
