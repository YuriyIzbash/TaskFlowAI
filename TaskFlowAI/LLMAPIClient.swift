//
//  LLMAPIClient.swift
//  TaskFlowAI
//
//  A tiny URLSession-based client for chat-style LLMs.
//

import Foundation

struct LLMAPIClient {
    struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    enum ClientError: LocalizedError {
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Received an unexpected response from the LLM service."
            }
        }
    }

    var baseURL: URL
    var model: String
    var apiKey: String?

    func send(systemPrompt: String, userPrompt: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let payload = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ClientError.invalidResponse
        }

        let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chat.choices.first?.message.content else {
            throw ClientError.invalidResponse
        }

        return content
    }
}

