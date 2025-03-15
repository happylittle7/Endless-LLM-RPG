
import Foundation

enum OpenRouterError: Error {
    case unknown
    case invalidURL
    case invalidResponse(String)
    case rateLimitReached
    case badResponseStatusCode(Int)
}
