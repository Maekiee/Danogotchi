import Foundation
import XCTest
@testable import Danogotchi

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = (URLRequest) throws -> (Int, Data)
    private static let lock = NSLock()
    private static var handlers: [String: Handler] = [:]

    static func register(host: String, handler: @escaping Handler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[host] = handler
    }

    static func remove(host: String) {
        lock.lock()
        defer { lock.unlock() }
        handlers.removeValue(forKey: host)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let handler = request.url?.host.flatMap { Self.handlers[$0] }
        Self.lock.unlock()
        do {
            let url = try XCTUnwrap(request.url)
            let (status, data) = try XCTUnwrap(handler)(request)
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

private struct TestEndpoint: Endpoint {
    let baseURL: String
    var path: String { "/v1/search" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { ["X-Test": "header"] }
    var queryItems: [URLQueryItem]? { [URLQueryItem(name: "query", value: "cat & dog 한글")] }
}

final class ApiClientTests: XCTestCase {
    private struct Payload: Decodable { let value: String }

    func test_requestEncodesQueryAndHeadersAndDecodesJSON() async throws {
        let fixture = try makeClient { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "header")
            XCTAssertEqual(request.url?.path, "/v1/search")
            let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.queryItems?.first?.value, "cat & dog 한글")
            return (200, Data(#"{"value":"ok"}"#.utf8))
        }
        defer { fixture.cleanup() }
        let value = try await fixture.client.request(TestEndpoint(baseURL: fixture.url.absoluteString), responseType: Payload.self)
        XCTAssertEqual(value.value, "ok")
    }

    func test_malformedJSONReturnsDecodingError() async throws {
        let fixture = try makeClient { _ in (200, Data("not json".utf8)) }
        defer { fixture.cleanup() }
        do {
            _ = try await fixture.client.request(TestEndpoint(baseURL: fixture.url.absoluteString), responseType: Payload.self)
            XCTFail("Expected decoding error")
        } catch NetworkError.decoding { }
        catch { XCTFail("Unexpected error: \(error)") }
    }

    func test_nonSuccessHTTPResponsesAreNotDecodedAsSuccess() async throws {
        for status in [400, 401, 403, 404, 503] {
            let fixture = try makeClient { _ in (status, Data(#"{"errors":["test failure"]}"#.utf8)) }
            defer { fixture.cleanup() }
            do {
                _ = try await fixture.client.request(TestEndpoint(baseURL: fixture.url.absoluteString), responseType: Payload.self)
                XCTFail("Expected HTTP error for \(status)")
            } catch let error as NetworkError {
                switch (status, error) {
                case (400, .badRequest(let messages)), (403, .forbidden(let messages)), (404, .notFound(let messages)):
                    XCTAssertEqual(messages, ["test failure"])
                case (401, .unauthorized): break
                case (503, .serviceUnavailable(let code)): XCTAssertEqual(code, 503)
                default: XCTFail("Unexpected error: \(error)")
                }
            } catch { XCTFail("Unexpected error: \(error)") }
        }
    }

    func test_dataReturnsOriginalBytes() async throws {
        let bytes = Data([0, 1, 2, 255])
        let fixture = try makeClient { _ in (200, bytes) }
        defer { fixture.cleanup() }
        let result = try await fixture.client.data(from: fixture.url)
        XCTAssertEqual(result, bytes)
    }

    func test_dataRejectsHTTPFailure() async throws {
        let fixture = try makeClient { _ in (503, Data("unavailable".utf8)) }
        defer { fixture.cleanup() }
        do {
            _ = try await fixture.client.data(from: fixture.url)
            XCTFail("Expected failure")
        } catch { XCTAssertTrue(error is NetworkError) }
    }

    func test_dataPreservesTransportFailure() async throws {
        let fixture = try makeClient { _ in throw URLError(.notConnectedToInternet) }
        defer { fixture.cleanup() }
        do {
            _ = try await fixture.client.data(from: fixture.url)
            XCTFail("Expected failure")
        } catch NetworkError.transport(let error) {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    private func makeClient(handler: @escaping StubURLProtocol.Handler) throws -> (client: DefaultApiClient, url: URL, cleanup: () -> Void) {
        let host = UUID().uuidString.lowercased() + ".example.test"
        let url = try XCTUnwrap(URL(string: "https://" + host))
        StubURLProtocol.register(host: host, handler: handler)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return (DefaultApiClient(session: session), url, {
            session.invalidateAndCancel()
            StubURLProtocol.remove(host: host)
        })
    }
}
