import Foundation

enum NetworkError: Error {
    case invalidURL
    case transport(URLError)
    case unauthorized
    case badRequest(message: [String])
    case forbidden(message: [String])
    case notFound(message: [String])
    case serviceUnavailable(statusCode: Int)
    case decoding(DecodingError)
    case unknown(Error)
}

extension NetworkError {
    var errorMessage: [String] {
        switch self {
        case .badRequest(let messages), .forbidden(let messages), .notFound(let messages):
            return messages
        default:
            return []
        }
    }
    
    var isCancelled: Bool {
        if case .transport(let error) = self { return error.code == .cancelled }
        return false
    }
}

struct ErrorResponse: Decodable {
    let errors: [String]
}
