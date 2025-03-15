

import SwiftUI

protocol OpenRouterAPIProvider {
    func completion(model: OpenRouterModel, prompt: String, temperature: Double, maxTokens: Int, stopTokens: [String], responseFormat: JSONSchema?) async throws -> String
}

extension OpenRouterAPIProvider where Self == OpenRouterManager {
    static var shared: OpenRouterAPIProvider { OpenRouterManager.shared }
}

extension OpenRouterAPIProvider {
    func completion(model: OpenRouterModel, prompt: String, temperature: Double, maxTokens: Int, stopTokens: [String] = [], responseFormat: JSONSchema? = nil) async throws -> String {
        try await completion(
            model: model,
            prompt: prompt,
            temperature: temperature,
            maxTokens: maxTokens,
            stopTokens: stopTokens,
            responseFormat: responseFormat
        )
    }
}

// MARK: - environment
extension EnvironmentValues {
    @Entry var openRouter: OpenRouterAPIProvider = .shared
}
