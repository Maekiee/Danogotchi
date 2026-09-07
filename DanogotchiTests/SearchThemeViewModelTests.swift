import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class SearchThemeViewModelTests: XCTestCase {
    func test_initialLoadRunsOnceAndMapsResults() async {
        let request = expectation(description: "initial request")
        let repository = ControlledSearchRepository(requests: [request])
        let screen = SearchThemeTestScreen(repository: repository)
        let loaded = expectation(description: "initial results")
        screen.onImages = { if $0 == ["library"] { loaded.fulfill() } }

        screen.appear.accept(())
        screen.appear.accept(())
        await fulfillment(of: [request], timeout: 2)
        await repository.complete(0, with: .success(photos(["library"], total: 1)))
        await fulfillment(of: [loaded], timeout: 2)

        let calls = await repository.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.query, "library")
        XCTAssertEqual(calls.first?.page, 1)
        XCTAssertFalse(screen.isEmpty)
    }

    func test_emptyResultAndFailureAreDistinctAndNextSearchCanSucceed() async {
        let requests = (0..<3).map { expectation(description: "request \($0)") }
        let repository = ControlledSearchRepository(requests: requests)
        let screen = SearchThemeTestScreen(repository: repository)
        let empty = expectation(description: "empty results")
        screen.onEmpty = { if $0 { empty.fulfill() } }
        screen.search("empty")
        await fulfillment(of: [requests[0]], timeout: 2)
        await repository.complete(0, with: .success(photos([], total: 0)))
        await fulfillment(of: [empty], timeout: 2)
        screen.onEmpty = nil

        let failed = expectation(description: "failure alert")
        screen.onAlert = { failed.fulfill() }
        screen.search("failure")
        await fulfillment(of: [requests[1]], timeout: 2)
        await repository.complete(1, with: .failure(URLError(.notConnectedToInternet)))
        await fulfillment(of: [failed], timeout: 2)
        XCTAssertFalse(screen.isEmpty)
        XCTAssertTrue(screen.ids.isEmpty)
        XCTAssertEqual(screen.alerts, ["잠시후 다시 시도해주세요"])

        let recovered = expectation(description: "recovered results")
        screen.onImages = { if $0 == ["recovered"] { recovered.fulfill() } }
        screen.search("recovered")
        await fulfillment(of: [requests[2]], timeout: 2)
        await repository.complete(2, with: .success(photos(["recovered"], total: 1)))
        await fulfillment(of: [recovered], timeout: 2)
    }

    func test_latestSearchWinsOverLateInitialResponseAndCancelledError() async {
        let requests = (0..<3).map { expectation(description: "request \($0)") }
        let repository = ControlledSearchRepository(requests: requests)
        let screen = SearchThemeTestScreen(repository: repository)
        screen.appear.accept(())
        await fulfillment(of: [requests[0]], timeout: 2)
        screen.search("old")
        await fulfillment(of: [requests[1]], timeout: 2)
        screen.search("latest")
        screen.search("latest") // 같은 검색어의 중복 요청 방지
        await fulfillment(of: [requests[2]], timeout: 2)
        let latest = expectation(description: "latest results")
        screen.onImages = { if $0 == ["latest"] { latest.fulfill() } }
        await repository.complete(2, with: .success(photos(["latest"], total: 1)))
        await fulfillment(of: [latest], timeout: 2)

        let stale = expectation(description: "cancelled requests must not update UI")
        stale.isInverted = true
        screen.onImages = { _ in stale.fulfill() }
        screen.onAlert = { stale.fulfill() }
        await repository.complete(0, with: .success(photos(["library"], total: 1)))
        // ApiClient가 취소 에러를 감싸더라도 Task의 취소 상태로 무시해야 한다.
        await repository.complete(1, with: .failure(NetworkError.unknown(URLError(.cancelled))))
        await fulfillment(of: [stale], timeout: 0.1)
        XCTAssertEqual(screen.ids, ["latest"])
        XCTAssertTrue(screen.alerts.isEmpty)
        let callCount = await repository.calls.count
        XCTAssertEqual(callCount, 3)
    }

    func test_paginationIgnoresDuplicatesAndRetriesFailedPage() async {
        let requests = (0..<4).map { expectation(description: "request \($0)") }
        let repository = ControlledSearchRepository(requests: requests)
        let screen = SearchThemeTestScreen(repository: repository)
        screen.search("book")
        await fulfillment(of: [requests[0]], timeout: 2)
        let first = expectation(description: "first page")
        screen.onImages = { if $0 == ["1"] { first.fulfill() } }
        await repository.complete(0, with: .success(photos(["1"], total: 3)))
        await fulfillment(of: [first], timeout: 2)
        screen.onImages = nil

        screen.next.accept(())
        screen.next.accept(())
        await fulfillment(of: [requests[1]], timeout: 2)
        let failed = expectation(description: "page failure")
        screen.onAlert = { failed.fulfill() }
        await repository.complete(1, with: .failure(URLError(.timedOut)))
        await fulfillment(of: [failed], timeout: 2)
        XCTAssertEqual(screen.ids, ["1"])

        screen.next.accept(())
        await fulfillment(of: [requests[2]], timeout: 2)
        let second = expectation(description: "second page retry")
        screen.onImages = { if $0 == ["1", "2"] { second.fulfill() } }
        await repository.complete(2, with: .success(photos(["2"], total: 3)))
        await fulfillment(of: [second], timeout: 2)

        screen.next.accept(())
        await fulfillment(of: [requests[3]], timeout: 2)
        let third = expectation(description: "third page")
        screen.onImages = { if $0 == ["1", "2", "3"] { third.fulfill() } }
        await repository.complete(3, with: .success(photos(["3"], total: 3)))
        await fulfillment(of: [third], timeout: 2)
        screen.next.accept(()) // 전체 개수 도달 후에는 요청하지 않는다.
        let pages = await repository.calls.map(\.page)
        XCTAssertEqual(pages, [1, 2, 2, 3])
    }

    func test_newSearchCancelsOldPageWithoutReleasingNewRequestLoadingState() async {
        let requests = (0..<4).map { expectation(description: "request \($0)") }
        let repository = ControlledSearchRepository(requests: requests)
        let screen = SearchThemeTestScreen(repository: repository)
        screen.search("old")
        await fulfillment(of: [requests[0]], timeout: 2)
        let first = expectation(description: "old first page")
        screen.onImages = { if $0 == ["old"] { first.fulfill() } }
        await repository.complete(0, with: .success(photos(["old"], total: 2)))
        await fulfillment(of: [first], timeout: 2)
        screen.next.accept(())
        await fulfillment(of: [requests[1]], timeout: 2)
        screen.search("new")
        await fulfillment(of: [requests[2]], timeout: 2)
        let replaced = expectation(description: "new first page")
        screen.onImages = { if $0 == ["new"] { replaced.fulfill() } }
        await repository.complete(2, with: .success(photos(["new"], total: 2)))
        await fulfillment(of: [replaced], timeout: 2)
        screen.next.accept(())
        await fulfillment(of: [requests[3]], timeout: 2)

        let stale = expectation(description: "old page must not update UI")
        stale.isInverted = true
        screen.onImages = { _ in stale.fulfill() }
        await repository.complete(1, with: .success(photos(["old page"], total: 2)))
        await fulfillment(of: [stale], timeout: 0.1)
        screen.next.accept(()) // 취소된 요청의 defer가 isLoading을 내렸다면 중복 호출된다.
        let completed = expectation(description: "new second page")
        screen.onImages = { if $0 == ["new", "new page"] { completed.fulfill() } }
        await repository.complete(3, with: .success(photos(["new page"], total: 2)))
        await fulfillment(of: [completed], timeout: 2)
        let calls = await repository.calls
        XCTAssertEqual(calls.map(\.query), ["old", "old", "new", "new"])
        XCTAssertEqual(calls.map(\.page), [1, 2, 1, 2])
    }

    func test_releasingViewModelCancelsPendingRequest() async {
        let request = expectation(description: "pending request")
        let repository = ControlledSearchRepository(requests: [request])
        let screen = SearchThemeTestScreen(repository: repository)
        screen.search("pending")
        await fulfillment(of: [request], timeout: 2)
        let isReleased = { [weak viewModel = screen.viewModel] in viewModel == nil }
        screen.viewModel = nil
        XCTAssertTrue(isReleased())

        let stale = expectation(description: "released screen must not receive results")
        stale.isInverted = true
        screen.onImages = { _ in stale.fulfill() }
        screen.onAlert = { stale.fulfill() }
        await repository.complete(0, with: .success(photos(["late"], total: 1)))
        await fulfillment(of: [stale], timeout: 0.1)
        let cancelled = await repository.cancelledCalls
        XCTAssertEqual(cancelled, [0])
    }

    private func photos(_ ids: [String], total: Int) -> SearchPhotoEntity {
        SearchPhotoEntity(total: total, total_pages: total, results: ids.map {
            PhotoEntity(id: $0, width: 100, height: 200, urls: ImageURLEntity(
                raw: "https://example.com/\($0)", small: "small", full: "full", regular: "regular", thumb: "thumb"
            ))
        })
    }
}

// 취소를 무시하고 응답하는 서버도 재현할 수 있도록 continuation을 직접 완료한다.
private actor ControlledSearchRepository: SearchThemeRepository {
    private let requests: [XCTestExpectation]
    private var pending: [Int: CheckedContinuation<SearchPhotoEntity, Error>] = [:]
    private(set) var calls: [(query: String, page: Int)] = []
    private(set) var cancelledCalls: [Int] = []

    init(requests: [XCTestExpectation]) {
        self.requests = requests
    }

    func searchPhotos(query: String, page: Int) async throws -> SearchPhotoEntity {
        let index = calls.count
        calls.append((query, page))
        guard index < requests.count else {
            XCTFail("Unexpected request: \(query), page \(page)")
            throw CancellationError()
        }
        defer { if Task.isCancelled { cancelledCalls.append(index) } }
        return try await withCheckedThrowingContinuation { continuation in
            pending[index] = continuation
            requests[index].fulfill()
        }
    }

    func complete(_ index: Int, with result: Result<SearchPhotoEntity, Error>) {
        guard let continuation = pending.removeValue(forKey: index) else {
            XCTFail("No pending request at index \(index)")
            return
        }
        continuation.resume(with: result)
    }
}

@MainActor
private final class SearchThemeTestScreen {
    let appear = PublishRelay<Void>()
    let text = BehaviorRelay<String>(value: "")
    let end = PublishRelay<Void>()
    let next = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
    var viewModel: SearchThemeViewModel?
    var ids: [String] = []
    var isEmpty = false
    var alerts: [String] = []
    var onImages: (([String]) -> Void)?
    var onEmpty: ((Bool) -> Void)?
    var onAlert: (() -> Void)?

    init(repository: SearchThemeRepository) {
        let viewModel = SearchThemeViewModel(
            searchThemeUseCase: DefaultSearchThemeUseCase(repository: repository),
            saveThemeUseCase: UnusedSaveThemeUseCase()
        )
        self.viewModel = viewModel
        let output = viewModel.transform(input: .init(
            viewWillAppear: appear.asObservable(), searchText: text.asObservable(),
            loadNextPage: next.asObservable(), textEndTrigger: end.asObservable(),
            selectedTheme: .never(), submitTapped: .never()
        ))
        output.themeImageList.drive(onNext: { [weak self] items in
            self?.ids = items.map(\.id)
            self?.onImages?(items.map(\.id))
        }).disposed(by: disposeBag)
        output.isEmptyResult.drive(onNext: { [weak self] value in
            self?.isEmpty = value
            self?.onEmpty?(value)
        }).disposed(by: disposeBag)
        output.alertMessage.emit(onNext: { [weak self] message in
            self?.alerts.append(message)
            self?.onAlert?()
        }).disposed(by: disposeBag)
    }

    func search(_ query: String) {
        text.accept(query)
        end.accept(())
    }
}

private struct UnusedSaveThemeUseCase: SaveThemeUseCase {
    func execute(rawUrl: String) -> Single<Result<Void, Error>> {
        XCTFail("Search must not save a theme")
        return .never()
    }
}
