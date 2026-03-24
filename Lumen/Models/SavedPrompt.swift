import Foundation

// MARK: - Prompt category

enum PromptCategory: String, CaseIterable, Codable, Sendable {
    case writing    = "Writing"
    case coding     = "Coding"
    case analysis   = "Analysis"
    case reasoning  = "Reasoning"
    case creative   = "Creative"
    case productivity = "Productivity"
    case custom     = "Custom"

    var icon: String {
        switch self {
        case .writing:      return "pencil.and.outline"
        case .coding:       return "chevron.left.forwardslash.chevron.right"
        case .analysis:     return "chart.bar.xaxis"
        case .reasoning:    return "brain"
        case .creative:     return "paintpalette"
        case .productivity: return "checklist"
        case .custom:       return "star"
        }
    }
}

// MARK: - SavedPrompt

struct SavedPrompt: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var title: String
    var content: String
    var category: PromptCategory
    var isFavorite: Bool
    var isBuiltIn: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: PromptCategory = .custom,
        isFavorite: Bool = false,
        isBuiltIn: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.isFavorite = isFavorite
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    static func == (lhs: SavedPrompt, rhs: SavedPrompt) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Built-in prompt library

extension SavedPrompt {
    static let builtIns: [SavedPrompt] = [
        // Writing
        SavedPrompt(title: "Improve my writing",
                    content: "Please improve the clarity, flow, and grammar of the following text while preserving its meaning and voice:\n\n",
                    category: .writing, isBuiltIn: true),
        SavedPrompt(title: "Summarize in 3 bullets",
                    content: "Summarize the following in exactly 3 concise bullet points:\n\n",
                    category: .writing, isBuiltIn: true),
        SavedPrompt(title: "Write a professional email",
                    content: "Write a professional email about the following topic. Be concise and courteous:\n\n",
                    category: .writing, isBuiltIn: true),
        SavedPrompt(title: "ELI5 — Explain simply",
                    content: "Explain the following concept as if I'm a complete beginner, using simple language and an analogy:\n\n",
                    category: .writing, isBuiltIn: true),

        // Coding
        SavedPrompt(title: "Review my code",
                    content: "Review the following code for bugs, security issues, performance improvements, and readability. Be specific:\n\n```\n\n```",
                    category: .coding, isBuiltIn: true),
        SavedPrompt(title: "Write unit tests",
                    content: "Write comprehensive unit tests for the following code. Cover happy paths, edge cases, and error conditions:\n\n```\n\n```",
                    category: .coding, isBuiltIn: true),
        SavedPrompt(title: "Explain this code",
                    content: "Explain what the following code does, step by step. Note any potential issues:\n\n```\n\n```",
                    category: .coding, isBuiltIn: true),
        SavedPrompt(title: "Refactor for clarity",
                    content: "Refactor the following code to be cleaner, more readable, and idiomatic. Explain your changes:\n\n```\n\n```",
                    category: .coding, isBuiltIn: true),

        // Analysis
        SavedPrompt(title: "Pros and cons",
                    content: "List the pros and cons of the following, then give a balanced recommendation:\n\n",
                    category: .analysis, isBuiltIn: true),
        SavedPrompt(title: "Critical analysis",
                    content: "Critically analyze the following. Identify assumptions, logical gaps, and areas for improvement:\n\n",
                    category: .analysis, isBuiltIn: true),
        SavedPrompt(title: "Compare options",
                    content: "Compare and contrast the following options in a clear table, then give your recommendation:\n\n",
                    category: .analysis, isBuiltIn: true),

        // Reasoning
        SavedPrompt(title: "Step-by-step reasoning",
                    content: "Think through the following problem step by step before giving your final answer:\n\n",
                    category: .reasoning, isBuiltIn: true),
        SavedPrompt(title: "Devil's advocate",
                    content: "Play devil's advocate and argue the strongest possible case against the following position:\n\n",
                    category: .reasoning, isBuiltIn: true),

        // Creative
        SavedPrompt(title: "Brainstorm ideas",
                    content: "Brainstorm 10 creative and diverse ideas for the following. Prioritize originality:\n\n",
                    category: .creative, isBuiltIn: true),
        SavedPrompt(title: "Continue the story",
                    content: "Continue the following story in the same style and tone, adding 2-3 paragraphs:\n\n",
                    category: .creative, isBuiltIn: true),

        // Productivity
        SavedPrompt(title: "Action plan",
                    content: "Create a clear, actionable step-by-step plan to accomplish the following goal:\n\n",
                    category: .productivity, isBuiltIn: true),
        SavedPrompt(title: "Meeting agenda",
                    content: "Create a structured meeting agenda for the following topic, including time slots and desired outcomes:\n\n",
                    category: .productivity, isBuiltIn: true),
    ]
}
