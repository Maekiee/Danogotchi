import Foundation

protocol ApiClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T

    /// 이미지 같은 원시 바이트를 절대 URL에서 그대로 받는다.
    /// request(_:responseType:)는 JSON 디코딩이 고정이고 baseURL + path 조합만 다뤄서 쓸 수 없다.
    func data(from url: URL) async throws -> Data
}

final class DefaultApiClient: ApiClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T where T : Decodable {
        let url = try makeRequest(endpoint)
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: url)
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        } catch {
            throw NetworkError.unknown(error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }
        
        switch http.statusCode {
        case 200..<300:
            break
        case 400:
            throw NetworkError.badRequest(message: messages(from: data))
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden(message: messages(from: data))
        case 404:
            throw NetworkError.notFound(message: messages(from: data))
        case 500..<600:
            throw NetworkError.serviceUnavailable(statusCode: http.statusCode)
        default:
            throw NetworkError.unknown(NSError(domain: "HTTPStatus", code: http.statusCode))
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    func data(from url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw NetworkError.transport(error)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }

        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.unknown(NSError(domain: "HTTPStatus", code: http.statusCode))
        }

        return data
    }

    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(string: endpoint.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
    
    private func messages(from data: Data) -> [String] {
        (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.errors ?? []
    }
}


