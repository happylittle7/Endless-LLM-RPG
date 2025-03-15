

import Foundation

private let openRouterAPIKey = "" //Please fill in your OpenRouter API Key here

final class OpenRouterManager: OpenRouterAPIProvider {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let session: URLSession
    
    static let shared = OpenRouterManager()
    
    init() {
        let config = URLSessionConfiguration.default
        var header = config.httpAdditionalHeaders ?? [:]
        header["Authorization"] = "Bearer \(openRouterAPIKey)"
        header["Content-Type"] = "application/json"
        config.httpAdditionalHeaders = header
        
        self.session = URLSession(configuration: config)
    }
    
    func completion(model: OpenRouterModel, prompt: String, temperature: Double, maxTokens: Int, stopTokens: [String], responseFormat: JSONSchema?) async throws -> String {
        let url = URL(string: "https://openrouter.ai/api/v1/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let request = CompletionRequest(
            model: model.path,
            prompt: prompt,
            temperature: temperature,
            maxTokens: maxTokens,
            stop: stopTokens,
            jsonSchema: responseFormat
        )
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let response = try await session.sendHTTPRequest(urlRequest, responseType: CompletionResponse.self)
        
        print("💸 花費 input \(response.usage.promptTokens) tokens, output \(response.usage.completionTokens) tokens")
        
        guard let completionText = response.choices.first?.text else {
            throw OpenRouterError.invalidResponse("沒有收到 choice")
        }
        
        return completionText
    }
}

private extension OpenRouterManager {
    struct CompletionRequest: Encodable {
        let model: String
        let prompt: String
        let temperature: Double
        let maxTokens: Int
        let stop: [String]
        // 以下為結構化輸出新增的參數
        let structuredOutputs: Bool
        let provider: [String: AnyEncodable]?
        let responseFormat: [String: AnyEncodable]?
        
        
        init(
            model: String,
            prompt: String,
            temperature: Double,
            maxTokens: Int,
            stop: [String],
            jsonSchema: JSONSchema?
        ) {
            self.model = model
            self.prompt = prompt
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.stop = stop
            self.structuredOutputs = jsonSchema != nil
            guard let jsonSchema else {
                self.responseFormat = nil
                self.provider = nil
                return
            }
            self.responseFormat = [
                "type": "json_schema",
                "json_schema": [
                    "name": jsonSchema.name,
                    "strict": true,
                    "schema": jsonSchema.schema
                ]
            ]
            self.provider = [
                "require_parameters": true
            ]
        }
        
        enum CodingKeys: String, CodingKey {
            case model
            case prompt
            case temperature
            case maxTokens = "max_tokens"
            case stop
            case structuredOutputs = "structured_outputs"
            case responseFormat = "response_format"
        
        }
    }
    
    struct CompletionResponse: Decodable {
        let choices: [Choice]
        let usage: Usage
        
        struct Choice: Decodable {
            let text: String
        }
        
        struct Usage: Codable {
            let promptTokens, completionTokens, totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }
}

private extension URLSession {
    func sendHTTPRequest<Response: Decodable>(_ request: URLRequest, responseType: Response.Type, retry: Int = 1) async throws -> Response {
        let (data, response) = try await data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 不是 HTTP 請求")
            throw OpenRouterError.invalidURL
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ 非正常狀態碼：\(httpResponse.statusCode)")
            throw OpenRouterError.badResponseStatusCode(httpResponse.statusCode)
        }
        
        do {
            let decodedData = try JSONDecoder().decode(responseType, from: data)
            return decodedData
            
        } catch {
            if let errorResponse = (try? JSONDecoder().decode(OpenRouterErrorResponse.self, from: data))?.error {
                switch errorResponse.code {
                    case 429:
                        if retry > 0 {
                            print("⏳ 超過額度，將自動於一秒後重試")
                            try await Task.sleep(for: .seconds(1))
                            return try await sendHTTPRequest(request, responseType: responseType, retry: retry - 1)
                        } else {
                            print("❌ 超過額度")
                            throw OpenRouterError.rateLimitReached
                        }
                        
                    default:
                        print("❌ error \(errorResponse.code): \(errorResponse.message)")
                        
                        if let data = String(data: data, encoding: .utf8) {
                            print("Error Detail: \(data)")
                        }
                }
                throw OpenRouterError.badResponseStatusCode(errorResponse.code)
            }
            
            if let data = String(data: data, encoding: .utf8) {
                print("❌ 轉換成 JSON 失敗：\(data)")
            }
            throw error
        }
    }
}
