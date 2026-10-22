import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class SearchThemeSavingTests: XCTestCase {
    private let rawURL = "https://images.example.test/photo?ixid=test"

    func test_noSelectionOrDeselectionPreventsSaving() async {
        let screen = Fixture()
        let started = expectation(description: "save must not start without a selection")
        started.isInverted = true
        await screen.save.setOnStart { started.fulfill() }

        screen.submit.accept(())
        XCTAssertTrue(screen.submitHidden)

        screen.selection.accept(rawURL)
        XCTAssertFalse(screen.submitHidden)
        screen.selection.accept(nil)
        screen.submit.accept(())
        XCTAssertTrue(screen.submitHidden)
        await fulfillment(of: [started], timeout: 0.1)
        let rawURLs = await screen.save.rawURLs
        XCTAssertTrue(rawURLs.isEmpty)
        XCTAssertEqual(screen.savingStates, [false])
        XCTAssertEqual(screen.savedCount, 0)
    }

    func test_pendingSaveBlocksDuplicateSubmitsAndFinishesOnlyAfterSuccess() async {
        let screen = Fixture()
        screen.selection.accept(rawURL)
        await submitAndWaitForStart(screen)
        screen.submit.accept(())
        screen.submit.accept(())

        let rawURLs = await screen.save.rawURLs
        XCTAssertEqual(rawURLs, [rawURL])
        XCTAssertEqual(screen.savingStates, [false, true])
        XCTAssertEqual(screen.savedCount, 0)
        XCTAssertTrue(screen.alerts.isEmpty)

        await finish(screen, with: .success(()))
        XCTAssertEqual(screen.savingStates, [false, true, false])
        XCTAssertEqual(screen.savedCount, 1)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_failureClearsLoadingWithoutFinishingAndSameSelectionCanRetry() async {
        let screen = Fixture()
        screen.selection.accept(rawURL)
        await submitAndWaitForStart(screen)
        await finish(screen, with: .failure(CocoaError(.fileWriteOutOfSpace)))

        XCTAssertEqual(screen.savingStates, [false, true, false])
        XCTAssertEqual(screen.savedCount, 0)
        XCTAssertEqual(screen.alerts, ["잠시후 다시 시도해주세요"])
        XCTAssertEqual(screen.reporter.errors.count, 1, "저장 실패는 한 번 보고한다")
        XCTAssertEqual(screen.selection.value, rawURL)
        XCTAssertFalse(screen.submitHidden)

        await submitAndWaitForStart(screen)
        let rawURLs = await screen.save.rawURLs
        XCTAssertEqual(rawURLs, [rawURL, rawURL])
        XCTAssertEqual(screen.savingStates.last, true)
        XCTAssertEqual(screen.savedCount, 0)
        await finish(screen, with: .success(()))
        XCTAssertEqual(screen.savingStates, [false, true, false, true, false])
        XCTAssertEqual(screen.savedCount, 1)
        XCTAssertEqual(screen.alerts.count, 1)
        XCTAssertEqual(screen.reporter.errors.count, 1)
    }

    func test_closingScreenDuringSaveDoesNotReportLateFailure() async throws {
        let save = ControlledSaveThemeUseCase()
        let reported = expectation(description: "a save cancelled by closing the screen must not be reported")
        reported.isInverted = true
        var viewModel: SearchThemeViewModel? = SearchThemeViewModel(
            searchThemeUseCase: UnusedSearchThemeUseCase(), saveThemeUseCase: save,
            reportError: { _ in reported.fulfill() }
        )
        let selection = BehaviorRelay<String?>(value: rawURL)
        let submit = PublishRelay<Void>()
        let output = try XCTUnwrap(viewModel).transform(input: .init(
            viewWillAppear: .never(), searchText: .never(), loadNextPage: .never(), textEndTrigger: .never(),
            selectedTheme: selection.asObservable(), submitTapped: submit.asObservable()
        ))
        let bag = DisposeBag()
        output.alertMessage.emit(onNext: { _ in reported.fulfill() }).disposed(by: bag)
        output.themeSaved.emit(onNext: { reported.fulfill() }).disposed(by: bag)
        let started = expectation(description: "save started")
        await save.setOnStart { started.fulfill() }
        submit.accept(())
        await fulfillment(of: [started], timeout: 2)

        // 화면이 닫혀 ViewModel이 해제된 뒤 저장이 실패로 끝난다
        weak var released = viewModel
        viewModel = nil
        XCTAssertNil(released)
        await save.complete(.failure(URLError(.cancelled)))

        await fulfillment(of: [reported], timeout: 0.2)
    }

    // MARK: - Helpers

    /// 저장은 ViewModel의 Task 안에서 시작되므로 시작될 때까지 기다린다
    private func submitAndWaitForStart(_ screen: Fixture) async {
        let started = expectation(description: "save started")
        await screen.save.setOnStart { started.fulfill() }
        screen.submit.accept(())
        await fulfillment(of: [started], timeout: 2)
    }

    /// 저장을 끝내고 로딩 표시가 꺼질 때까지 기다린다
    private func finish(_ screen: Fixture, with result: Result<Void, Error>) async {
        let finished = expectation(description: "save finished")
        screen.onSavingState = { if !$0 { finished.fulfill() } }
        await screen.save.complete(result)
        await fulfillment(of: [finished], timeout: 2)
        screen.onSavingState = nil
    }

    @MainActor
    private final class Fixture {
        let selection = BehaviorRelay<String?>(value: nil)
        let submit = PublishRelay<Void>()
        let save = ControlledSaveThemeUseCase()
        let reporter = ErrorRecorder()
        let viewModel: SearchThemeViewModel
        private let disposeBag = DisposeBag()
        var savingStates: [Bool] = []
        var savedCount = 0
        var alerts: [String] = []
        var submitHidden = true
        var onSavingState: ((Bool) -> Void)?

        init() {
            viewModel = SearchThemeViewModel(
                searchThemeUseCase: UnusedSearchThemeUseCase(),
                saveThemeUseCase: save,
                reportError: { [reporter] in reporter.record($0) }
            )
            let output = viewModel.transform(input: .init(
                viewWillAppear: .never(), searchText: .never(), loadNextPage: .never(), textEndTrigger: .never(),
                selectedTheme: selection.asObservable(), submitTapped: submit.asObservable()
            ))
            output.isSaving.drive(onNext: { [weak self] in
                self?.savingStates.append($0)
                self?.onSavingState?($0)
            }).disposed(by: disposeBag)
            output.themeSaved.emit(onNext: { [weak self] in self?.savedCount += 1 }).disposed(by: disposeBag)
            output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: disposeBag)
            output.buttonEnable.drive(onNext: { [weak self] in self?.submitHidden = $0 }).disposed(by: disposeBag)
        }
    }
}

// 저장 완료 시점을 테스트가 직접 정하도록 continuation을 붙잡아 둔다
private actor ControlledSaveThemeUseCase: SaveThemeUseCase {
    private(set) var rawURLs: [String] = []
    private var pending: CheckedContinuation<Void, Error>?
    private var onStart: (@Sendable () -> Void)?

    func setOnStart(_ handler: @escaping @Sendable () -> Void) {
        onStart = handler
    }

    func execute(rawUrl: String) async throws {
        rawURLs.append(rawUrl)
        XCTAssertNil(pending, "A pending save must not be replaced by another submit")
        try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            onStart?()
            onStart = nil
        }
    }

    func complete(_ result: Result<Void, Error>) {
        guard let pending else {
            XCTFail("No pending save")
            return
        }
        self.pending = nil
        pending.resume(with: result)
    }
}

private struct UnusedSearchThemeUseCase: SearchThemeUseCase {
    func execute(query: String, page: Int) async throws -> SearchPhotoEntity {
        XCTFail("Saving a selected theme must not start a search")
        throw URLError(.unsupportedURL)
    }
}

/// viewModel이 let이라 init 안에서 self를 캡처할 수 없어 별도 객체에 기록한다
private final class ErrorRecorder {
    private(set) var errors: [Error] = []
    func record(_ error: Error) { errors.append(error) }
}
