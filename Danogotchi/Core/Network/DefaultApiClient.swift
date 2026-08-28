import Foundation

protocol ApiClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T
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
        case 2..<300:
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
    
    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(string: APIConfig.baseURL + endpoint.path)
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


