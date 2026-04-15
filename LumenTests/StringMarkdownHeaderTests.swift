import Foundation
import Testing
@testable import Lumen

@Suite("String+Markdown — block markdown preprocessing")
struct StringMarkdownHeaderTests {

    // Access the private preprocessor through a public round-trip via
    // AttributedString.fromMarkdown. We read the resulting characters back
    // out as a String so we can assert on the rewritten form.
    private func rendered(_ input: String) -> String {
        let attributed = AttributedString.fromMarkdown(input)
        return String(attributed.characters)
    }

    @Test("renders ATX headings as bold instead of literal hashes")
    func rendersAtxHeadings() {
        // A level-3 heading should no longer produce a literal `### `.
        let out = rendered("### 1. Bugs & Edge Cases\nThe primary issue is X.")
        #expect(!out.contains("###"))
        #expect(out.contains("1. Bugs & Edge Cases"))
        #expect(out.contains("The primary issue is X."))
    }

    @Test("supports levels 1 through 6")
    func supportsAllSixHeadingLevels() {
        for level in 1...6 {
            let hashes = String(repeating: "#", count: level)
            let out = rendered("\(hashes) Heading")
            #expect(!out.contains("#"), "Level \(level) heading should not leave literal #")
            #expect(out.contains("Heading"), "Level \(level) heading should preserve text")
        }
    }

    @Test("strips trailing hashes from headings")
    func stripsTrailingHashes() {
        let out = rendered("## Heading ##")
        #expect(!out.contains("#"))
        #expect(out.contains("Heading"))
    }

    @Test("ignores headings inside fenced code blocks")
    func ignoresHeadingsInsideCodeBlocks() {
        // `# foo` inside a fenced code block must be preserved literally so
        // the Swift syntax highlighter still receives the exact source.
        let input = """
        Prose before.
        ```swift
        // # Not a heading
        let x = 1
        ```
        Prose after.
        """
        let out = rendered(input)
        #expect(out.contains("// # Not a heading"))
    }

    @Test("rewrites unordered list markers to bullet glyph")
    func rewritesUnorderedLists() {
        for marker in ["-", "*", "+"] {
            let out = rendered("\(marker) first item")
            #expect(out.contains("\u{2022}"), "Expected bullet glyph for marker \(marker)")
            #expect(out.contains("first item"))
        }
    }

    @Test("preserves inline emphasis and links")
    func preservesInlineMarkdown() {
        let input = "See **bold** and *italic* and [link](https://example.com)."
        let out = rendered(input)
        // Inline markdown is consumed by Foundation's parser and becomes
        // attributes, not literal characters, so these should no longer
        // appear as plain characters in the rendered string.
        #expect(!out.contains("**"))
        #expect(!out.contains("](https"))
        #expect(out.contains("bold"))
        #expect(out.contains("italic"))
        #expect(out.contains("link"))
    }

    @Test("renders horizontal rules as visible separators")
    func rendersHorizontalRules() {
        let out = rendered("above\n---\nbelow")
        #expect(out.contains("above"))
        #expect(out.contains("below"))
        #expect(!out.contains("---"))
    }

    @Test("rewrites blockquotes to em-dash italic lines")
    func rewritesBlockquotes() {
        let out = rendered("> a pithy remark")
        #expect(!out.contains(">"))
        #expect(out.contains("a pithy remark"))
    }

    @Test("handles empty heading content gracefully")
    func handlesEmptyHeading() {
        let out = rendered("### \n\nThen content.")
        #expect(out.contains("Then content."))
        #expect(!out.contains("###"))
    }

    @Test("accepts bare empty heading with no trailing space")
    func acceptsBareEmptyHeading() {
        // CommonMark treats `###` (just hashes, end of line) as a valid empty
        // heading. Our previous regex `^#{1,6}\s+` required at least one
        // whitespace after the hashes, so `###` alone leaked through as
        // literal `###` in the rendered text.
        let out = rendered("Before.\n###\nAfter.")
        #expect(!out.contains("###"))
        #expect(out.contains("Before."))
        #expect(out.contains("After."))
    }

    @Test("recognizes horizontal rules with more than three chars or spaces")
    func recognizesExtendedHorizontalRules() {
        // CommonMark allows 3 or more of `-`, `*`, or `_`, and spaces between.
        for rule in ["---", "----", "-----", "***", "____", "- - -", "* * *"] {
            let out = rendered("above\n\(rule)\nbelow")
            #expect(out.contains("above"))
            #expect(out.contains("below"))
            // The raw marker characters should not survive.
            #expect(!out.contains(rule), "Expected \(rule) to be rewritten")
        }
    }

    @Test("preserves leading whitespace on indented lists")
    func preservesLeadingIndentation() {
        let out = rendered("    - indented item")
        #expect(out.hasPrefix("    "))
        #expect(out.contains("indented item"))
    }
}
