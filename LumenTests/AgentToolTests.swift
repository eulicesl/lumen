import Testing
@testable import Lumen

@Suite("AgentTool — built-in tools")
struct AgentToolTests {

    // MARK: - DateTimeTool

    @Test("DateTimeTool returns a non-empty string")
    func dateTimeToolDefault() async {
        let tool = DateTimeTool()
        let result = await tool.run(input: "")
        #expect(!result.isEmpty)
    }

    @Test("DateTimeTool date-only format excludes time component")
    func dateTimeToolDateOnly() async {
        let tool = DateTimeTool()
        let result = await tool.run(input: "date")
        #expect(!result.isEmpty)
        #expect(!result.contains(":"))
    }

    @Test("DateTimeTool time-only format contains colon")
    func dateTimeToolTimeOnly() async {
        let tool = DateTimeTool()
        let result = await tool.run(input: "time")
        #expect(result.contains(":"))
    }

    // MARK: - CalculatorTool

    @Test("CalculatorTool evaluates simple addition")
    func calculatorAddition() async {
        let tool = CalculatorTool()
        let result = await tool.run(input: "2 + 3")
        #expect(result == "5")
    }

    @Test("CalculatorTool evaluates multiplication")
    func calculatorMultiplication() async {
        let tool = CalculatorTool()
        let result = await tool.run(input: "4 * 7")
        #expect(result == "28")
    }

    @Test("CalculatorTool handles floating-point result")
    func calculatorFloat() async {
        let tool = CalculatorTool()
        let result = await tool.run(input: "10 / 4")
        #expect(result == "2.5")
    }

    @Test("CalculatorTool returns error on empty input")
    func calculatorEmpty() async {
        let tool = CalculatorTool()
        let result = await tool.run(input: "")
        #expect(result.hasPrefix("Error"))
    }

    // MARK: - WordCountTool

    @Test("WordCountTool counts words correctly")
    func wordCountBasic() async {
        let tool = WordCountTool()
        let result = await tool.run(input: "Hello world foo")
        #expect(result.contains("Words: 3"))
    }

    @Test("WordCountTool counts characters correctly")
    func wordCountChars() async {
        let tool = WordCountTool()
        let result = await tool.run(input: "Hello")
        #expect(result.contains("Characters: 5"))
    }

    @Test("WordCountTool handles empty string")
    func wordCountEmpty() async {
        let tool = WordCountTool()
        let result = await tool.run(input: "")
        #expect(result.contains("Words: 0"))
    }

    // MARK: - Base64Tool

    @Test("Base64Tool encodes a string")
    func base64Encode() async {
        let tool = Base64Tool()
        let result = await tool.run(input: "encode:Hello")
        #expect(result == "SGVsbG8=")
    }

    @Test("Base64Tool decodes a string")
    func base64Decode() async {
        let tool = Base64Tool()
        let result = await tool.run(input: "decode:SGVsbG8=")
        #expect(result == "Hello")
    }

    @Test("Base64Tool returns error for invalid decode")
    func base64DecodeInvalid() async {
        let tool = Base64Tool()
        let result = await tool.run(input: "decode:!!!invalid!!!")
        #expect(result.hasPrefix("Error"))
    }

    @Test("Base64Tool returns error for missing prefix")
    func base64MissingPrefix() async {
        let tool = Base64Tool()
        let result = await tool.run(input: "Hello")
        #expect(result.hasPrefix("Error"))
    }

    // MARK: - URLEncoderTool

    @Test("URLEncoderTool encodes special characters")
    func urlEncode() async {
        let tool = URLEncoderTool()
        let result = await tool.run(input: "encode:hello world")
        #expect(result.contains("hello%20world") || result == "hello+world")
    }

    @Test("URLEncoderTool decodes percent-encoded string")
    func urlDecode() async {
        let tool = URLEncoderTool()
        let result = await tool.run(input: "decode:hello%20world")
        #expect(result == "hello world")
    }

    @Test("URLEncoderTool returns error for missing prefix")
    func urlMissingPrefix() async {
        let tool = URLEncoderTool()
        let result = await tool.run(input: "hello world")
        #expect(result.hasPrefix("Error"))
    }

    // MARK: - Registry

    @Test("AgentToolRegistry finds tool by name")
    func registryLookupByName() {
        let tool = AgentToolRegistry.tool(named: "calculator")
        #expect(tool != nil)
        #expect(tool?.name == "calculator")
    }

    @Test("AgentToolRegistry returns nil for unknown name")
    func registryLookupUnknown() {
        let tool = AgentToolRegistry.tool(named: "nonexistent_tool_xyz")
        #expect(tool == nil)
    }

    @Test("AgentToolRegistry system prompt contains all tool names")
    func registrySystemPrompt() {
        let prompt = AgentToolRegistry.systemPromptFragment
        for tool in AgentToolRegistry.all {
            #expect(prompt.contains(tool.name))
        }
    }

    @Test("AgentToolRegistry has 5 built-in tools")
    func registryCount() {
        #expect(AgentToolRegistry.all.count == 5)
    }
}
