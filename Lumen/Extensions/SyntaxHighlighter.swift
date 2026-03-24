import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
private typealias PlatColor = UIColor
private typealias PlatFont  = UIFont
#elseif canImport(AppKit)
import AppKit
private typealias PlatColor = NSColor
private typealias PlatFont  = NSFont
#endif

enum SyntaxHighlighter {

    // MARK: - Theme colors (designed for dark code-block background)

    private static let plainColor   = PlatColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
    private static let keywordColor = PlatColor(red: 0.82, green: 0.50, blue: 0.92, alpha: 1)
    private static let stringColor  = PlatColor(red: 0.95, green: 0.65, blue: 0.35, alpha: 1)
    private static let commentColor = PlatColor(red: 0.48, green: 0.72, blue: 0.48, alpha: 1)
    private static let numberColor  = PlatColor(red: 0.50, green: 0.80, blue: 0.95, alpha: 1)
    private static let typeColor    = PlatColor(red: 0.50, green: 0.90, blue: 0.90, alpha: 1)

    // MARK: - Keyword sets per language

    private static let keywords: [String: Set<String>] = [
        "swift": [
            "func", "var", "let", "struct", "class", "enum", "protocol", "extension",
            "if", "else", "guard", "switch", "case", "default", "for", "while", "do",
            "try", "catch", "throw", "throws", "rethrows", "return", "break", "continue",
            "fallthrough", "import", "public", "private", "internal", "fileprivate", "open",
            "static", "final", "override", "init", "deinit", "subscript", "typealias",
            "self", "super", "nil", "true", "false", "async", "await", "actor",
            "nonisolated", "in", "where", "is", "as", "any", "some", "inout", "lazy",
            "weak", "unowned", "mutating", "get", "set", "willSet", "didSet", "repeat"
        ],
        "python": [
            "def", "class", "import", "from", "as", "if", "elif", "else", "for", "while",
            "try", "except", "finally", "with", "return", "yield", "break", "continue",
            "pass", "raise", "and", "or", "not", "in", "is", "lambda", "global",
            "nonlocal", "del", "assert", "True", "False", "None", "async", "await"
        ],
        "javascript": [
            "const", "let", "var", "function", "class", "import", "export", "default",
            "return", "if", "else", "for", "while", "do", "switch", "case", "break",
            "continue", "try", "catch", "finally", "throw", "new", "delete", "typeof",
            "instanceof", "in", "of", "this", "null", "undefined", "true", "false",
            "async", "await", "from", "extends", "super", "static", "get", "set", "yield"
        ],
        "typescript": [
            "const", "let", "var", "function", "class", "interface", "type", "import",
            "export", "default", "return", "if", "else", "for", "while", "do", "switch",
            "case", "break", "continue", "try", "catch", "finally", "throw", "new",
            "typeof", "instanceof", "in", "of", "this", "null", "undefined", "true",
            "false", "async", "await", "from", "extends", "implements", "super", "static",
            "enum", "namespace", "as", "any", "never", "void", "readonly", "abstract",
            "public", "private", "protected", "keyof", "infer", "declare", "override"
        ],
        "kotlin": [
            "fun", "val", "var", "class", "object", "interface", "enum", "when", "if",
            "else", "for", "while", "do", "return", "break", "continue", "try", "catch",
            "finally", "throw", "import", "package", "true", "false", "null", "this",
            "super", "is", "as", "in", "companion", "data", "sealed", "abstract",
            "override", "open", "suspend", "by", "where", "init", "internal", "private",
            "protected", "public", "inline", "reified", "crossinline", "noinline"
        ],
        "go": [
            "func", "var", "const", "type", "struct", "interface", "package", "import",
            "return", "if", "else", "for", "range", "switch", "case", "default", "break",
            "continue", "goto", "go", "defer", "select", "chan", "map", "nil", "true",
            "false", "make", "new", "append", "len", "cap", "delete", "close", "panic",
            "recover", "error", "string", "int", "int64", "bool", "byte", "rune", "float64"
        ],
        "rust": [
            "fn", "let", "mut", "const", "static", "struct", "enum", "impl", "trait",
            "use", "mod", "pub", "super", "self", "Self", "crate", "return", "if",
            "else", "for", "while", "loop", "match", "break", "continue", "true",
            "false", "None", "Some", "Ok", "Err", "async", "await", "dyn", "where",
            "type", "move", "ref", "in", "as", "box", "unsafe", "extern"
        ],
        "java": [
            "public", "private", "protected", "static", "final", "abstract", "class",
            "interface", "enum", "extends", "implements", "import", "package", "return",
            "if", "else", "for", "while", "do", "switch", "case", "default", "break",
            "continue", "try", "catch", "finally", "throw", "throws", "new", "this",
            "super", "null", "true", "false", "void", "int", "long", "double", "float",
            "boolean", "char", "byte", "short", "synchronized", "volatile", "transient"
        ],
        "bash":   ["if", "then", "else", "elif", "fi", "for", "do", "done", "while",
                   "case", "esac", "function", "return", "echo", "exit", "export",
                   "local", "source", "alias", "true", "false", "test", "read"],
        "shell":  ["if", "then", "else", "elif", "fi", "for", "do", "done", "while",
                   "case", "esac", "function", "return", "echo", "exit", "export",
                   "local", "source", "alias", "true", "false"],
        "sql": [
            "SELECT", "FROM", "WHERE", "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "FULL",
            "ON", "GROUP", "BY", "ORDER", "HAVING", "INSERT", "INTO", "VALUES", "UPDATE",
            "SET", "DELETE", "CREATE", "TABLE", "DROP", "ALTER", "ADD", "COLUMN",
            "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "DISTINCT", "AS", "AND", "OR",
            "NOT", "IN", "IS", "NULL", "LIKE", "BETWEEN", "EXISTS", "UNION", "ALL",
            "INDEX", "VIEW", "DATABASE", "SCHEMA", "CONSTRAINT", "DEFAULT", "UNIQUE",
            "select", "from", "where", "join", "inner", "left", "right", "outer",
            "on", "group", "by", "order", "having", "insert", "into", "values",
            "update", "set", "delete", "create", "table", "drop", "alter", "add",
            "column", "primary", "key", "foreign", "references", "distinct", "as",
            "and", "or", "not", "in", "is", "null", "like", "between", "exists",
            "union", "all", "index", "view"
        ],
        "css": [
            "important", "media", "keyframes", "from", "to", "root", "not", "nth-child",
            "hover", "focus", "active", "before", "after", "first-child", "last-child"
        ]
    ]

    private static let lineCommentPrefixes: [String: String] = [
        "swift": "//", "kotlin": "//", "javascript": "//", "typescript": "//",
        "java": "//", "go": "//", "rust": "//", "c": "//", "cpp": "//",
        "csharp": "//", "python": "#", "ruby": "#", "bash": "#", "shell": "#",
        "yaml": "#", "toml": "#", "r": "#", "perl": "#"
    ]

    private static let blockCommentLanguages: Set<String> = [
        "swift", "kotlin", "javascript", "typescript", "java", "go", "rust",
        "c", "cpp", "csharp", "css", "objc"
    ]

    private static let typeLanguages: Set<String> = [
        "swift", "kotlin", "java", "typescript", "javascript", "csharp", "rust"
    ]

    // MARK: - Public API

    static func highlight(code: String, language: String) -> AttributedString {
        let lang = normalize(language)

        let codeFont = PlatFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let ns = NSMutableAttributedString(string: code)
        let fullRange = NSRange(code.startIndex..., in: code)

        ns.addAttribute(.foregroundColor, value: plainColor, range: fullRange)
        ns.addAttribute(.font, value: codeFont, range: fullRange)

        var protected: [NSRange] = []

        if blockCommentLanguages.contains(lang) {
            apply(pattern: "/\\*[\\s\\S]*?\\*/", to: ns, code: code,
                  color: commentColor, options: [.dotMatchesLineSeparators],
                  protected: &protected)
        }

        if let prefix = lineCommentPrefixes[lang] {
            let escaped = NSRegularExpression.escapedPattern(for: prefix)
            apply(pattern: "\(escaped)[^\n]*", to: ns, code: code,
                  color: commentColor, protected: &protected)
        }

        apply(pattern: #""([^"\\]|\\.)*""#, to: ns, code: code,
              color: stringColor, protected: &protected)
        apply(pattern: #"'([^'\\]|\\.)*'"#, to: ns, code: code,
              color: stringColor, protected: &protected)

        if lang == "javascript" || lang == "typescript" {
            apply(pattern: #"`[^`]*`"#, to: ns, code: code,
                  color: stringColor, protected: &protected)
        }

        if let kws = keywords[lang] {
            for kw in kws {
                let escaped = NSRegularExpression.escapedPattern(for: kw)
                apply(pattern: "\\b\(escaped)\\b", to: ns, code: code,
                      color: keywordColor, skipProtected: true, protected: &protected)
            }
        }

        apply(pattern: "\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", to: ns, code: code,
              color: numberColor, skipProtected: true, protected: &protected)

        if typeLanguages.contains(lang) {
            apply(pattern: "\\b[A-Z][a-zA-Z0-9_]*\\b", to: ns, code: code,
                  color: typeColor, skipProtected: true, protected: &protected)
        }

        return AttributedString(ns)
    }

    // MARK: - Private helpers

    private static func apply(
        pattern: String,
        to ns: NSMutableAttributedString,
        code: String,
        color: PlatColor,
        options: NSRegularExpression.Options = [],
        skipProtected: Bool = false,
        protected protectedRanges: inout [NSRange]
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let fullRange = NSRange(code.startIndex..., in: code)
        regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
            guard let r = match?.range else { return }
            if skipProtected && protectedRanges.contains(where: { NSIntersectionRange($0, r).length > 0 }) {
                return
            }
            ns.addAttribute(.foregroundColor, value: color, range: r)
            if !skipProtected { protectedRanges.append(r) }
        }
    }

    private static func normalize(_ lang: String) -> String {
        switch lang.lowercased().trimmingCharacters(in: .whitespaces) {
        case "js":                       return "javascript"
        case "ts":                       return "typescript"
        case "py":                       return "python"
        case "rb":                       return "ruby"
        case "sh", "zsh", "fish":        return "bash"
        case "c++":                      return "cpp"
        case "c#":                       return "csharp"
        case "objc", "objective-c":      return "objc"
        case "kt":                       return "kotlin"
        case "rs":                       return "rust"
        case "json":                     return "json"
        case "md", "markdown":           return "markdown"
        default:                         return lang.lowercased().trimmingCharacters(in: .whitespaces)
        }
    }
}
