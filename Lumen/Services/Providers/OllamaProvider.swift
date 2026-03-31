import Foundation

actor OllamaProvider: AIProvider {
    let id = "ollama"
    let displayName = "Ollama"
    let providerType: AIProviderType = .ollama

    private(set) var baseURL: URL
    private(set) var bearerToken: String?

    private let session: URLSession
    private var availabilityCache: (value: Bool, timestamp: Date)?
    private let cacheTTL: TimeInterval = 10

    init(baseURL: URL = URL(string: "http://localhost:11434")!, bearerToken: String? = nil) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: config)
    }

    func updateBaseURL(_ url: URL) {
        self.baseURL = url
        self.availabilityCache = nil
    }

    func updateBearerToken(_ token: String?) {
        self.bearerToken = token
    }

    func checkAvailability() async -> Bool {
        if let cache = availabilityCache,
           Date().timeIntervalSince(cache.timestamp) < cacheTTL {
            return cache.value
        }
        let tagsURL = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: tagsURL)
        request.timeoutInterval = 5
        addAuthHeaders(to: &request)
        do {
            let (_, response) = try await session.data(for: request)
            let available = (response as? HTTPURLResponse)?.statusCode == 200
            availabilityCache = (available, Date())
            return available
        } catch {
            availabilityCache = (false, Date())
            return false
        }
    }

    func listModels() async throws -> [AIModel] {
        let tagsURL = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: tagsURL)
        request.timeoutInterval = 5
        addAuthHeaders(to: &request)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIProviderError.invalidResponse("No HTTP response from /api/tags.")
            }
            guard httpResponse.statusCode == 200 else {
                throw AIProviderError.invalidResponse("HTTP \(httpResponse.statusCode) from /api/tags.")
            }
            let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            return decoded.models.map { ollamaModel in
                AIModel(
                    id: "ollama.\(ollamaModel.name)",
                    name: ollamaModel.name,
                    providerType: .ollama,
                    supportsImages: ollamaModel.name.lowercased().contains("llava") ||
                                    ollamaModel.name.lowercased().contains("vision"),
                    supportsStreaming: true
                )
            }
        } catch let error as AIProviderError {
            throw error
        } catch let error as URLError {
            throw AIProviderError.networkError(error)
        } catch {
            throw AIProviderError.invalidResponse(error.localizedDescription)
        }
    }

    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let chatURL = self.baseURL.appendingPathComponent("api/chat")
                    var request = URLRequest(url: chatURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    self.addAuthHeaders(to: &request)

                    let ollamaMessages = self.buildMessages(from: messages, options: options)
                    let body = OllamaChatRequest(
                        model: model.name,
                        messages: ollamaMessages,
                        stream: options.stream,
                        options: OllamaOptions(temperature: Double(options.temperature))
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    let (stream, response) = try await self.session.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode) else {
                        throw AIProviderError.invalidResponse("Ollama returned non-200 status")
                    }

                    for try await line in stream.lines {
                        guard !line.isEmpty else { continue }
                        guard let lineData = line.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(OllamaChatResponse.self, from: lineData)
                        let token = ChatToken(
                            text: chunk.message.content,
                            isComplete: chunk.done,
                            tokenCount: chunk.done ? chunk.evalCount : nil,
                            finishReason: chunk.done ? .stop : nil
                        )
                        continuation.yield(token)
                        if chunk.done { break }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: AIProviderError.cancelled)
                } catch let error as AIProviderError {
                    continuation.finish(throwing: error)
                } catch let error as URLError {
                    continuation.finish(throwing: AIProviderError.networkError(error))
                } catch {
                    continuation.finish(throwing: AIProviderError.invalidResponse(error.localizedDescription))
                }
            }
        }
    }

    private func buildMessages(from messages: [ChatMessage], options: ChatOptions) -> [OllamaMessage] {
        var ollamaMessages: [OllamaMessage] = []
        if let systemPrompt = options.systemPrompt, !systemPrompt.isEmpty {
            ollamaMessages.append(OllamaMessage(role: "system", content: systemPrompt))
        }
        ollamaMessages += messages
            .filter { !$0.isSystem }
            .map { OllamaMessage(role: $0.role.rawValue, content: $0.content) }
        return ollamaMessages
    }

    private func addAuthHeaders(to request: inout URLRequest) {
        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}

// MARK: - Ollama API Types

private struct OllamaTagsResponse: Decodable {
    let models: [OllamaModelInfo]

    struct OllamaModelInfo: Decodable {
        let name: String
        let size: Int64?
        let digest: String?
    }
}

private struct OllamaChatRequest: Encodable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let options: OllamaOptions?
}

private struct OllamaMessage: Codable {
    let role: String
    let content: String
}

private struct OllamaOptions: Encodable {
    let temperature: Double?
}

private struct OllamaChatResponse: Decodable {
    let message: OllamaMessage
    let done: Bool
    let evalCount: Int?

    enum CodingKeys: String, CodingKey {
        case message, done
        case evalCount = "eval_count"
    }
}
