import RxCocoa
import RxSwift
import UIKit
import XCTest
@testable import Danogotchi

private final class TemporaryImageFileManager: FileManager, @unchecked Sendable {
    let root: URL
    var failsDirectoryLookup = false
    init(root: URL) { self.root = root; super.init() }
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask,
                      appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        if failsDirectoryLookup { throw CocoaError(.fileWriteOutOfSpace) }
        return root
    }
}

final class TestUserInfo: UserInfoProtocol {
    var username: String?
    var userId: String?
    var currentThemeUrl: String?
    var isStudyReminderEnabled = true
    private let fileName = BehaviorRelay<String?>(value: nil)
    var currentThemeImageFileName: String? {
        get { fileName.value }
        set { fileName.accept(newValue) }
    }
    var themeImageFileNameObservable: Observable<String?> { fileName.asObservable() }
}

private actor ImageApiStub: ApiClient {
    private var responses: [Result<Data, Error>]
    private(set) var urls: [URL] = []
    init(_ responses: [Result<Data, Error>]) { self.responses = responses }
    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        throw URLError(.unsupportedURL)
    }
    func data(from url: URL) async throws -> Data {
        urls.append(url)
        guard !responses.isEmpty else { throw URLError(.badServerResponse) }
        return try responses.removeFirst().get()
    }
}

@MainActor
final class ThemeImagePersistenceTests: XCTestCase {
    private let rawURL = "https://images.example.test/photo?ixid=test"

    func test_successReplacesBytesPublishesFileAndRemovesPreviousImage() async throws {
        let data = imageData(color: .blue)
        let fixture = try Fixture(responses: [.success(data)])
        defer { fixture.cleanup() }
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        try result.get()
        let file = try XCTUnwrap(fixture.repository.storedImageFileURL())
        XCTAssertEqual(try Data(contentsOf: file), data)
        XCTAssertEqual(file.pathExtension, "png")
        XCTAssertNotEqual(file, fixture.previousFile)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.previousFile.path))
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, rawURL)
        let decoded = try XCTUnwrap(ImageDecoder.decode(fileURL: file, maxPixelSize: 4))
        XCTAssertLessThanOrEqual(max(decoded.size.width, decoded.size.height), 4)
    }

    func test_failedFirstFormatFallsBackAndPreservesOriginalQuery() async throws {
        let fixture = try Fixture(responses: [.failure(URLError(.cannotDecodeContentData)), .success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        try await fixture.repository.replace(rawUrl: rawURL).value.get()
        let urls = await fixture.api.urls
        let queries = urls.compactMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        XCTAssertEqual(queries.map { $0.first(where: { $0.name == "fm" })?.value }, ["heic", "webp"])
        XCTAssertTrue(queries.allSatisfy { $0.contains(URLQueryItem(name: "ixid", value: "test")) })
        XCTAssertEqual(fixture.repository.storedImageFileURL()?.pathExtension, "png")
    }

    func test_invalidFirstImageAlsoFallsBack() async throws {
        let fixture = try Fixture(responses: [.success(Data("invalid".utf8)), .success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        try await fixture.repository.replace(rawUrl: rawURL).value.get()
        let requests = await fixture.api.urls
        XCTAssertEqual(requests.count, 2)
    }

    func test_downloadFailureKeepsPreviousBytesAndSelection() async throws {
        let fixture = try Fixture(responses: [.failure(URLError(.notConnectedToInternet)), .failure(URLError(.notConnectedToInternet))])
        defer { fixture.cleanup() }
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        XCTAssertThrowsError(try result.get())
        try assertPreviousImage(fixture)
    }

    func test_invalidBytesNeverReplacePreviousImage() async throws {
        let fixture = try Fixture(responses: [.success(Data()), .success(Data("invalid".utf8))])
        defer { fixture.cleanup() }
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        XCTAssertThrowsError(try result.get())
        try assertPreviousImage(fixture)
    }

    func test_fileStorageFailureKeepsPreviousBytesAndSelection() async throws {
        let fixture = try Fixture(responses: [.success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        fixture.fileManager.failsDirectoryLookup = true
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        XCTAssertThrowsError(try result.get())
        try assertPreviousImage(fixture)
    }

    private func assertPreviousImage(_ fixture: Fixture, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(fixture.userInfo.currentThemeImageFileName, "previous.png", file: file, line: line)
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, "https://images.example.test/previous?ixid=test", file: file, line: line)
        XCTAssertEqual(try Data(contentsOf: fixture.previousFile), fixture.previousData, file: file, line: line)
    }

    private func imageData(color: UIColor) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    @MainActor
    private final class Fixture {
        let root: URL
        let fileManager: TemporaryImageFileManager
        let api: ImageApiStub
        let userInfo = TestUserInfo()
        let repository: DefaultThemeImageRepository
        let previousFile: URL
        let previousData = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }

        init(responses: [Result<Data, Error>]) throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            fileManager = TemporaryImageFileManager(root: root)
            api = ImageApiStub(responses)
            let storage = ImageFileStorage(directoryName: "ThemeImage", fileManager: fileManager)
            previousFile = try storage.save(previousData, fileName: "previous.png")
            userInfo.currentThemeUrl = "https://images.example.test/previous?ixid=test"
            userInfo.currentThemeImageFileName = "previous.png"
            repository = DefaultThemeImageRepository(apiClient: api, storage: storage, userInfo: userInfo)
        }
        func cleanup() { try? FileManager.default.removeItem(at: root) }
    }
}
