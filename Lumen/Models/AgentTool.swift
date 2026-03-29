import Foundation

// MARK: - Agent tool protocol

protocol AgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parameterDescription: String { get }
    func run(input: String) async -> String
}

// MARK: - Tool registry

struct AgentToolRegistry: Sendable {
    static let all: [any AgentTool] = [
        DateTimeTool(),
        CalculatorTool(),
        WordCountTool(),
        Base64Tool(),
        URLEncoderTool(),
    ]

    static func tool(named name: String) -> (any AgentTool)? {
        all.first { $0.name.lowercased() == name.lowercased() }
    }

    /// System prompt fragment describing all tools
    static var systemPromptFragment: String {
        let descriptions = all.map { tool in
            "- **\(tool.name)**: \(tool.description)\n  Input: \(tool.parameterDescription)"
        }.joined(separator: "\n")

        return """
        You have access to the following tools. To use a tool, output exactly:
        [[TOOL:\(all.first?.name ?? "tool_name")|your input here]]

        Available tools:
        \(descriptions)

        After calling a tool, you will receive [[RESULT:...]] with the output. \
        You may then continue your response or call another tool.
        """
    }
}

// MARK: - Built-in tools

struct DateTimeTool: AgentTool {
    let name = "datetime"
    let description = "Returns the current date, time, and timezone."
    let parameterDescription = "Optional format string (e.g., 'date', 'time', 'full'). Leave empty for full date+time."

    func run(input: String) async -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = .current
        switch input.lowercased().trimmingCharacters(in: .whitespaces) {
        case "date":
            formatter.dateStyle = .full
            formatter.timeStyle = .none
        case "time":
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
        default:
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
        }
        let tz = TimeZone.current.identifier
        return "\(formatter.string(from: now)) (\(tz))"
    }
}

struct CalculatorTool: AgentTool {
    let name = "calculator"
    let description = "Evaluates a mathematical expression and returns the result."
    let parameterDescription = "A math expression using +, -, *, /, (, ) and numbers. E.g., '(15 * 3) + 7'"

    func run(input: String) async -> String {
        let cleaned = input.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return "Error: empty expression" }

        let decimalized = cleaned.replacingOccurrences(
            of: #"(?<![\w.])(\d+)(?![\w.])"#,
            with: "$1.0",
            options: .regularExpression
        )

        let expr = NSExpression(format: decimalized)
        if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
            let double = result.doubleValue
            if double == double.rounded() && !cleaned.contains(".") && !cleaned.contains("/") {
                return String(Int(double))
            }
            return String(format: "%.6g", double)
        }
        return "Error: could not evaluate '\(cleaned)'"
    }
}

struct WordCountTool: AgentTool {
    let name = "wordcount"
    let description = "Counts words, characters, and sentences in a text."
    let parameterDescription = "The text to analyze."

    func run(input: String) async -> String {
        let words = input.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let chars = input.count
        let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        return "Words: \(words.count), Characters: \(chars), Sentences: \(sentences)"
    }
}

struct Base64Tool: AgentTool {
    let name = "base64"
    let description = "Encodes text to Base64 or decodes Base64 to text."
    let parameterDescription = "'encode:<text>' to encode, or 'decode:<base64>' to decode."

    func run(input: String) async -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("encode:") {
            let text = String(trimmed.dropFirst("encode:".count))
            return Data(text.utf8).base64EncodedString()
        } else if trimmed.lowercased().hasPrefix("decode:") {
            let encoded = String(trimmed.dropFirst("decode:".count)).trimmingCharacters(in: .whitespaces)
            if let data = Data(base64Encoded: encoded),
               let decoded = String(data: data, encoding: .utf8) {
                return decoded
            }
            return "Error: invalid Base64 input"
        }
        return "Error: use 'encode:<text>' or 'decode:<base64>'"
    }
}

struct URLEncoderTool: AgentTool {
    let name = "urlencode"
    let description = "Percent-encodes or decodes a URL string."
    let parameterDescription = "'encode:<text>' or 'decode:<text>'"

    func run(input: String) async -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("encode:") {
            let text = String(trimmed.dropFirst("encode:".count))
            return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Error"
        } else if trimmed.lowercased().hasPrefix("decode:") {
            let text = String(trimmed.dropFirst("decode:".count))
            return text.removingPercentEncoding ?? "Error"
        }
        return "Error: use 'encode:<text>' or 'decode:<text>'"
    }
}
