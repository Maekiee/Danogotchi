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

// MARK: - Crashlytics 이슈 묶음 — code는 case 순서와 무관한 고정 값
extension NetworkError: CustomNSError {
    static var errorDomain: String { "danogotchi.network" }

    var errorCode: Int {
        switch self {
        case .invalidURL: return 1
        case .transport: return 2
        case .unauthorized: return 3
        case .badRequest: return 4
        case .forbidden: return 5
        case .notFound: return 6
        case .serviceUnavailable: return 7
        case .decoding: return 8
        case .unknown: return 9
        }
    }

    /// 서버 메시지·디코딩 값은 넣지 않는다
    var errorUserInfo: [String: Any] {
        switch self {
        case .transport(let error):
            return [CrashReporter.InfoKey.urlErrorCode: error.code.rawValue, NSUnderlyingErrorKey: error]
        case .serviceUnavailable(let statusCode):
            return [CrashReporter.InfoKey.httpStatus: statusCode]
        case .decoding(let error):
            let (kind, path) = Self.describe(error)
            return [
                CrashReporter.InfoKey.decodingKind: kind,
                CrashReporter.InfoKey.codingPath: path.map(\.stringValue).joined(separator: ".")
            ]
        case .unknown(let error):
            return [NSUnderlyingErrorKey: error]
        case .invalidURL, .unauthorized, .badRequest, .forbidden, .notFound:
            return [:]
        }
    }

    private static func describe(_ error: DecodingError) -> (kind: String, path: [CodingKey]) {
        switch error {
        case .typeMismatch(_, let context): return ("typeMismatch", context.codingPath)
        case .valueNotFound(_, let context): return ("valueNotFound", context.codingPath)
        case .keyNotFound(let key, let context): return ("keyNotFound", context.codingPath + [key])
        case .dataCorrupted(let context): return ("dataCorrupted", context.codingPath)
        @unknown default: return ("unknown", [])
        }
    }
}
