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
    private let requestReceived: XCTestExpectation?
    private(set) var urls: [URL] = []
    init(_ responses: [Result<Data, Error>], requestReceived: XCTestExpectation? = nil) {
        self.responses = responses
        self.requestReceived = requestReceived
    }
    nonisolated func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        throw URLError(.unsupportedURL)
    }
    func data(from url: URL) async throws -> Data {
        urls.append(url)
        if let requestReceived, urls.count <= requestReceived.expectedFulfillmentCount {
            requestReceived.fulfill()
        }
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
        let published = expectation(description: "new file is readable before the previous file is removed")
        let observation = fixture.repository.storedImageChanged
            .compactMap { $0 }
            .filter { $0 != fixture.previousFile }
            .subscribe(onNext: { file in
                XCTAssertEqual(try? Data(contentsOf: file), data)
                XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.previousFile.path))
                published.fulfill()
            })
        defer { observation.dispose() }
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        try result.get()
        await fulfillment(of: [published], timeout: 2)
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

    func test_requestUsesScreenPixelsCenterCropAndQuality() async throws {
        let fixture = try Fixture(responses: [.success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        try await fixture.repository.replace(rawUrl: rawURL).value.get()
        let urls = await fixture.api.urls
        XCTAssertEqual(urls.count, 1)
        let url = try XCTUnwrap(urls.first)
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let size = UIScreen.main.nativeBounds.size
        let expected = ["w": String(Int(size.width)), "h": String(Int(size.height)),
                        "fit": "crop", "crop": "center", "fm": "heic", "q": "85", "ixid": "test"]
        for (name, value) in expected {
            XCTAssertEqual(items.filter { $0.name == name }.map(\.value), [value], name)
        }
    }

    func test_legacyQueryIsReplacedForBothFormatAttempts() async throws {
        let fixture = try Fixture(responses: [.failure(URLError(.cannotDecodeContentData)), .success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        let legacyURL = rawURL + "&fm=jpg&q=80&w=4000&h=3000&fit=max&crop=faces&fm=png"
        try await fixture.repository.replace(rawUrl: legacyURL).value.get()
        let urls = await fixture.api.urls
        XCTAssertEqual(urls.count, 2)
        let size = UIScreen.main.nativeBounds.size
        for (url, format) in zip(urls, ["heic", "webp"]) {
            let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            let expected = ["w": String(Int(size.width)), "h": String(Int(size.height)),
                            "fit": "crop", "crop": "center", "fm": format, "q": "85", "ixid": "test"]
            for (name, value) in expected {
                XCTAssertEqual(items.filter { $0.name == name }.map(\.value), [value], name)
            }
        }
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, legacyURL)
    }

    func test_urlWithoutQueryReceivesTransformationParameters() async throws {
        let fixture = try Fixture(responses: [.success(imageData(color: .blue))])
        defer { fixture.cleanup() }
        try await fixture.repository.replace(rawUrl: "https://images.example.test/photo").value.get()
        let urls = await fixture.api.urls
        let url = try XCTUnwrap(urls.first)
        XCTAssertEqual(url.path, "/photo")
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(items.contains(URLQueryItem(name: "fm", value: "heic")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "q", value: "85")))
    }

    func test_fileWriteFailureKeepsPreviousBytesAndSelection() async throws {
        let fixture = try Fixture(responses: [.success(imageData(color: .blue))])
        let directory = fixture.previousFile.deletingLastPathComponent()
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            fixture.cleanup()
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        let result = try await fixture.repository.replace(rawUrl: rawURL).value
        XCTAssertThrowsError(try result.get())
        try assertPreviousImage(fixture)
    }

    func test_observingStoredImageReadsLocalBytesWithoutDownloading() async throws {
        let request = expectation(description: "stored image must not trigger a download")
        request.isInverted = true
        let fixture = try Fixture(responses: [], requestReceived: request)
        defer { fixture.cleanup() }
        let loaded = expectation(description: "initial local file")
        let useCase = DefaultObserveThemeUseCase(themeImageRepository: fixture.repository)
        let observation = useCase.execute().subscribe(onNext: { file in
            XCTAssertEqual(file, fixture.previousFile)
            XCTAssertEqual(file.flatMap { try? Data(contentsOf: $0) }, fixture.previousData)
            loaded.fulfill()
        }, onError: { XCTFail("Unexpected observation error: \($0)") })
        defer { observation.dispose() }
        await fulfillment(of: [loaded, request], timeout: 0.1)
        let urls = await fixture.api.urls
        XCTAssertTrue(urls.isEmpty)
    }

    func test_missingFileWithoutSavedURLDoesNotAttemptRecovery() async throws {
        let request = expectation(description: "no saved URL must not trigger a download")
        request.isInverted = true
        let fixture = try Fixture(responses: [], requestReceived: request)
        defer { fixture.cleanup() }
        try FileManager.default.removeItem(at: fixture.previousFile)
        fixture.userInfo.currentThemeUrl = nil
        let empty = expectation(description: "initial missing file")
        let useCase = DefaultObserveThemeUseCase(themeImageRepository: fixture.repository)
        let observation = useCase.execute().subscribe(onNext: {
            XCTAssertNil($0)
            empty.fulfill()
        })
        defer { observation.dispose() }
        await fulfillment(of: [empty, request], timeout: 0.1)
        let urls = await fixture.api.urls
        XCTAssertTrue(urls.isEmpty)
        XCTAssertNil(fixture.repository.storedImageFileURL())
    }

    func test_missingFileIsRestoredAndPublishedFromSavedURL() async throws {
        let data = imageData(color: .blue)
        let fixture = try Fixture(responses: [.success(data)])
        defer { fixture.cleanup() }
        try FileManager.default.removeItem(at: fixture.previousFile)
        let restored = expectation(description: "restored file")
        let useCase = DefaultObserveThemeUseCase(themeImageRepository: fixture.repository)
        let observation = useCase.execute().compactMap { $0 }.subscribe(onNext: { file in
            XCTAssertTrue(file.isFileURL)
            XCTAssertEqual(try? Data(contentsOf: file), data)
            restored.fulfill()
        }, onError: { XCTFail("Unexpected recovery error: \($0)") })
        defer { observation.dispose() }
        await fulfillment(of: [restored], timeout: 2)
        let urls = await fixture.api.urls
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first?.path, "/previous")
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, "https://images.example.test/previous?ixid=test")
        XCTAssertNotNil(fixture.repository.storedImageFileURL())
    }

    func test_failedRecoveryPreservesSelectionAndObservationAcceptsLaterSave() async throws {
        let attempts = expectation(description: "HEIC and WebP recovery attempts")
        attempts.expectedFulfillmentCount = 2
        let data = imageData(color: .blue)
        let fixture = try Fixture(responses: [.failure(URLError(.notConnectedToInternet)),
                                             .failure(URLError(.notConnectedToInternet)), .success(data)],
                                  requestReceived: attempts)
        defer { fixture.cleanup() }
        try FileManager.default.removeItem(at: fixture.previousFile)
        let saved = expectation(description: "observation stays active after failed recovery")
        let useCase = DefaultObserveThemeUseCase(themeImageRepository: fixture.repository)
        let observation = useCase.execute().compactMap { $0 }.subscribe(onNext: { file in
            XCTAssertEqual(try? Data(contentsOf: file), data)
            saved.fulfill()
        }, onError: { XCTFail("Recovery failure must not terminate observation: \($0)") })
        defer { observation.dispose() }
        await fulfillment(of: [attempts], timeout: 2)
        XCTAssertEqual(fixture.userInfo.currentThemeImageFileName, "previous.png")
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, "https://images.example.test/previous?ixid=test")
        XCTAssertNil(fixture.repository.storedImageFileURL())

        try await fixture.repository.replace(rawUrl: rawURL).value.get()
        await fulfillment(of: [saved], timeout: 2)
        let urls = await fixture.api.urls
        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, rawURL)
    }

    // MARK: - 사진첩에서 고른 이미지

    func test_localPhotoReplacesBytesClearsRawUrlAndRemovesPreviousImage() async throws {
        let data = imageData(color: .blue)
        let fixture = try Fixture(responses: [])
        defer { fixture.cleanup() }
        let published = expectation(description: "new file is published")
        let observation = fixture.repository.storedImageChanged
            .compactMap { $0 }
            .filter { $0 != fixture.previousFile }
            .subscribe(onNext: { file in
                XCTAssertEqual(try? Data(contentsOf: file), data)
                published.fulfill()
            })
        defer { observation.dispose() }

        try await fixture.repository.replace(imageData: data)
        await fulfillment(of: [published], timeout: 2)

        let file = try XCTUnwrap(fixture.repository.storedImageFileURL())
        XCTAssertEqual(try Data(contentsOf: file), data)
        XCTAssertEqual(file.pathExtension, "png")
        XCTAssertNotEqual(file, fixture.previousFile)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.previousFile.path))
        // 로컬 사진은 복구할 원본이 없으므로 URL을 비운다
        XCTAssertNil(fixture.userInfo.currentThemeUrl)
        let urls = await fixture.api.urls
        XCTAssertTrue(urls.isEmpty, "사진첩 저장은 네트워크를 쓰지 않는다")
    }

    func test_storedExtensionFollowsActualBytesNotPickerMetadata() async throws {
        let fixtureFile = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "theme-pattern", withExtension: "heic")
        )
        let data = try Data(contentsOf: fixtureFile)
        let fixture = try Fixture(responses: [])
        defer { fixture.cleanup() }

        try await fixture.repository.replace(imageData: data)

        let file = try XCTUnwrap(fixture.repository.storedImageFileURL())
        XCTAssertEqual(file.pathExtension, "heic")
        XCTAssertEqual(try Data(contentsOf: file), data)
    }

    func test_unsupportedBytesNeverReplacePreviousImage() async throws {
        let fixture = try Fixture(responses: [])
        defer { fixture.cleanup() }

        do {
            try await fixture.repository.replace(imageData: Data("invalid".utf8))
            XCTFail("Unsupported bytes must not be stored")
        } catch {
            XCTAssertEqual(error as? PhotoThemeError, .unsupportedFormat)
        }
        try assertPreviousImage(fixture)
    }

    func test_localPhotoFileStorageFailureKeepsPreviousBytesAndSelection() async throws {
        let fixture = try Fixture(responses: [])
        defer { fixture.cleanup() }
        fixture.fileManager.failsDirectoryLookup = true

        do {
            try await fixture.repository.replace(imageData: imageData(color: .blue))
            XCTFail("A failed file write must not replace the stored image")
        } catch {
            // 어떤 실패든 기존 배경과 복구 정보가 남아 있어야 한다
        }
        try assertPreviousImage(fixture)
    }

    func test_localThemeIsNotRecoveredAfterFileLoss() async throws {
        let request = expectation(description: "local theme must not trigger a download")
        request.isInverted = true
        let fixture = try Fixture(responses: [], requestReceived: request)
        defer { fixture.cleanup() }
        try await fixture.repository.replace(imageData: imageData(color: .blue))
        try FileManager.default.removeItem(at: XCTUnwrap(fixture.repository.storedImageFileURL()))

        let empty = expectation(description: "missing local file")
        let useCase = DefaultObserveThemeUseCase(themeImageRepository: fixture.repository)
        let observation = useCase.execute().subscribe(onNext: {
            XCTAssertNil($0)
            empty.fulfill()
        })
        defer { observation.dispose() }
        await fulfillment(of: [empty, request], timeout: 0.1)
        let urls = await fixture.api.urls
        XCTAssertTrue(urls.isEmpty)
    }

    func test_localSaveThenRemoteSaveRestoresRecovery() async throws {
        let remoteData = imageData(color: .green)
        let fixture = try Fixture(responses: [.success(remoteData)])
        defer { fixture.cleanup() }

        try await fixture.repository.replace(imageData: imageData(color: .blue))
        XCTAssertNil(fixture.repository.lastSelectedRawUrl)

        try await fixture.repository.replace(rawUrl: rawURL).value.get()

        XCTAssertEqual(fixture.repository.lastSelectedRawUrl, rawURL)
        XCTAssertEqual(fixture.userInfo.currentThemeUrl, rawURL)
        let file = try XCTUnwrap(fixture.repository.storedImageFileURL())
        XCTAssertEqual(try Data(contentsOf: file), remoteData)
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

        init(responses: [Result<Data, Error>], requestReceived: XCTestExpectation? = nil) throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            fileManager = TemporaryImageFileManager(root: root)
            api = ImageApiStub(responses, requestReceived: requestReceived)
            let storage = ImageFileStorage(directoryName: "ThemeImage", fileManager: fileManager)
            previousFile = try storage.save(previousData, fileName: "previous.png")
            userInfo.currentThemeUrl = "https://images.example.test/previous?ixid=test"
            userInfo.currentThemeImageFileName = "previous.png"
            repository = DefaultThemeImageRepository(apiClient: api, storage: storage, userInfo: userInfo)
        }
        func cleanup() { try? FileManager.default.removeItem(at: root) }
    }
}
