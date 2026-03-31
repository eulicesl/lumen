import SwiftUI

struct CodeBlockView: View {
    let language: String
    let code: String

    private var displayLanguage: String {
        language.isEmpty ? "plaintext" : language.lowercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            Divider().background(Color(white: 0.28))
            codeBody
        }
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: LumenRadius.sm)
                .strokeBorder(Color(white: 0.28), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(displayLanguage) code block")
        .accessibilityHint("Contains selectable code and a copy action")
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: LumenSpacing.xs) {
            Text(displayLanguage)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))

            Spacer()

            Button(action: copyCode) {
                Label("Copy code", systemImage: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.55))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy code")
            .accessibilityHint("Copies the full code block")
        }
        .padding(.horizontal, LumenSpacing.sm)
        .padding(.vertical, LumenSpacing.xs)
        .background(Color(white: 0.15))
    }

    // MARK: - Code body

    private var codeBody: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(SyntaxHighlighter.highlight(code: code, language: language))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(LumenSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(white: 0.11))
    }

    // MARK: - Actions

    private func copyCode() {
        #if os(iOS)
        UIPasteboard.general.string = code
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        HapticEngine.impact(.light)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CodeBlockView(
                language: "swift",
                code: """
                @Observable
                final class ChatStore: @unchecked Sendable {
                    var messages: [ChatMessage] = []
                    var inputText: String = ""

                    func send() async {
                        guard !inputText.isEmpty else { return }
                        // Send message to AI
                        let text = inputText
                        inputText = ""
                        print("Sending: \\(text)")
                    }
                }
                """
            )
            CodeBlockView(
                language: "python",
                code: """
                def fibonacci(n: int) -> int:
                    # Base cases
                    if n <= 1:
                        return n
                    return fibonacci(n - 1) + fibonacci(n - 2)

                result = fibonacci(10)
                print(f"Result: {result}")  # 55
                """
            )
        }
        .padding()
    }
    .background(Color.black)
}
