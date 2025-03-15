

struct OpenRouterErrorResponse: Decodable {
    let error: Error
    
    struct Error: Decodable {
        let code: Int
        let message: String
    }
}
