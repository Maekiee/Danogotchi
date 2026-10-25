import UIKit
import XCTest
@testable import Danogotchi

final class RemoteImageLoaderTests: XCTestCase {
    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        var count: Int { lock.withLock { value } }
        func increment() { lock.withLock { value += 1 } }
    }

    private struct Fixture {
        let loader: RemoteImageLoader
        let url: URL
        let calls: CallCounter
        let cleanup: () -> Void
    }

    private func makeFixture(status: Int, body: Data) throws -> Fixture {
        let host = UUID().uuidString.lowercased() + ".example.test"
        let url = try XCTUnwrap(URL(string: "https://\(host)/image.png"))
        let calls = CallCounter()
        StubURLProtocol.register(host: host) { _ in
            calls.increment()
            return (status, body)
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return Fixture(loader: RemoteImageLoader(session: session), url: url, calls: calls) {
            session.invalidateAndCancel()
            StubURLProtocol.remove(host: host)
        }
    }

    /// scale 1로 그려야 UIImage(data:)가 돌려주는 크기가 2×2 포인트다
    private func pngData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format).pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    func test_successfulLoadReturnsImageAndServesSecondRequestFromCache() async throws {
        let fixture = try makeFixture(status: 200, body: pngData())
        defer { fixture.cleanup() }
        XCTAssertNil(fixture.loader.cachedImage(for: fixture.url))

        let first = await fixture.loader.load(url: fixture.url)
        XCTAssertEqual(first?.size, CGSize(width: 2, height: 2))
        XCTAssertNotNil(fixture.loader.cachedImage(for: fixture.url))

        let second = await fixture.loader.load(url: fixture.url)
        XCTAssertTrue(second === first)
        XCTAssertEqual(fixture.calls.count, 1)
    }

    func test_httpFailureReturnsNilAndIsNotCached() async throws {
        let fixture = try makeFixture(status: 404, body: pngData())
        defer { fixture.cleanup() }

        let image = await fixture.loader.load(url: fixture.url)

        XCTAssertNil(image)
        XCTAssertNil(fixture.loader.cachedImage(for: fixture.url))
        _ = await fixture.loader.load(url: fixture.url)
        XCTAssertEqual(fixture.calls.count, 2)
    }

    func test_nonImageBodyReturnsNil() async throws {
        let fixture = try makeFixture(status: 200, body: Data("not an image".utf8))
        defer { fixture.cleanup() }

        let image = await fixture.loader.load(url: fixture.url)

        XCTAssertNil(image)
        XCTAssertNil(fixture.loader.cachedImage(for: fixture.url))
    }
}
