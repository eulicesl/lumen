import Testing
@testable import Lumen

@Suite("String+Markdown — agent markup stripping")
struct StringAgentMarkupTests {

    // MARK: - Basic removal

    @Test("strips simple tool call markup")
    func stripSimpleToolCall() {
        let input = "Hello [[TOOL:calculator|2+2]] world"
        let result = input.stripAgentMarkup()
        #expect(result == "Hello  world")
    }

    @Test("strips simple tool result markup")
    func stripSimpleToolResult() {
        let input = "The answer is [[RESULT:4]] as expected"
        let result = input.stripAgentMarkup()
        #expect(result == "The answer is  as expected")
    }

    @Test("strips both tool calls and results")
    func stripBothMarkup() {
        let input = """
        Let me check. [[TOOL:calculator|2+2]]
        [[RESULT:4]]
        The answer is 4.
        """
        let result = input.stripAgentMarkup()
        #expect(result.contains("Let me check."))
        #expect(result.contains("The answer is 4."))
        #expect(!result.contains("[[TOOL:"))
        #expect(!result.contains("[[RESULT:"))
    }

    // MARK: - Bracket handling (reviewer feedback)

    @Test("strips tool call when payload contains brackets")
    func stripToolCallWithBrackets() {
        let input = "Check [[TOOL:decoder|decode [base64] text]] done"
        let result = input.stripAgentMarkup()
        #expect(!result.contains("[[TOOL:"))
        #expect(result.contains("done"))
    }

    @Test("strips tool result when payload contains brackets")
    func stripToolResultWithBrackets() {
        let input = "Output: [[RESULT:array = [1, 2, 3]]] end"
        let result = input.stripAgentMarkup()
        #expect(!result.contains("[[RESULT:"))
        #expect(result.contains("end"))
    }

    @Test("strips tool result when payload is an empty array")
    func stripToolResultWithEmptyArrayPayload() {
        let input = "Output: [[RESULT:[]]] end"
        let result = input.stripAgentMarkup()
        #expect(result == "Output:  end")
        #expect(!result.contains("]]]"))
    }

    @Test("strips tool call when payload contains markdown link brackets")
    func stripToolCallWithMarkdownLinkPayload() {
        let input = "Check [[TOOL:fetch|see [guide](https://example.com)]] done"
        let result = input.stripAgentMarkup()
        #expect(result == "Check  done")
    }

    // MARK: - Passthrough (no markup)

    @Test("returns unchanged string when no markup present")
    func noMarkupPassthrough() {
        let input = "Just a normal message with no agent markup."
        let result = input.stripAgentMarkup()
        #expect(result == input)
    }

    @Test("preserves normal bracket usage")
    func preserveNormalBrackets() {
        let input = "Use array[0] and dict[key] normally."
        let result = input.stripAgentMarkup()
        #expect(result == input)
    }

    // MARK: - Fast path

    @Test("fast path: mayContainAgentMarkup returns false for clean text")
    func fastPathClean() {
        #expect(!"Hello world".mayContainAgentMarkup)
    }

    @Test("fast path: mayContainAgentMarkup returns true for tool markup")
    func fastPathToolCall() {
        #expect("abc [[TOOL:calc|1+1]] xyz".mayContainAgentMarkup)
    }

    @Test("fast path: mayContainAgentMarkup returns true for result markup")
    func fastPathResult() {
        #expect("abc [[RESULT:2]] xyz".mayContainAgentMarkup)
    }

    // MARK: - Whitespace normalization

    @Test("collapses excessive blank lines after stripping")
    func collapseBlankLines() {
        let input = "Hello\n\n\n\n\n[[TOOL:test|x]]\n\n\n\nWorld"
        let result = input.stripAgentMarkup()
        // Should have at most two consecutive newlines
        #expect(!result.contains("\n\n\n"))
        #expect(result.contains("Hello"))
        #expect(result.contains("World"))
    }

    @Test("trims leading and trailing whitespace")
    func trimWhitespace() {
        let input = "  \n[[TOOL:test|x]] Hello  \n  "
        let result = input.stripAgentMarkup()
        #expect(result == "Hello")
    }

    @Test("streaming mode preserves surrounding whitespace")
    func streamingModePreservesWhitespace() {
        let input = "Hello [[TOOL:test|x]]\n"
        let result = input.stripAgentMarkup(normalizeWhitespace: false, trimEdges: false)
        #expect(result == "Hello \n")
    }
}
