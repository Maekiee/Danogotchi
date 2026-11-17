import Foundation
import XCTest

/// host별 핸들러로 응답을 꾸민다 — ApiClientTests·RemoteImageLoaderTests가 함께 쓴다
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
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
