

import Foundation

enum OpenRouterModel: CaseIterable {
    case llama
    case hermes
    case mistral
    case geminiFlash
    case gpt4oMini
    
    var name: String {
        switch self {
            case .llama:
                "Llama"
            case .hermes:
                "Hermes"
            case .mistral:
                "Mistral"
            case .geminiFlash:
                "Gemini"
            case .gpt4oMini:
                "OpenAI"
        }
    }
    
    var path: String {
        switch self {
            case .llama:
                "meta-llama/llama-3.3-70b-instruct"
            case .hermes:
                "nousresearch/hermes-2-pro-llama-3-8b"
            case .mistral:
                "mistralai/mistral-saba"
            case .geminiFlash:
                "google/gemini-2.0-flash-001"
            case .gpt4oMini:
                "openai/gpt-4o-mini"
        }
    }
}

extension OpenRouterModel: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(path)
    }
}
