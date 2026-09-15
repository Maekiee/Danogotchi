import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class SearchThemeSavingTests: XCTestCase {
    private let rawURL = "https://images.example.test/photo?ixid=test"

    func test_noSelectionOrDeselectionPreventsSaving() {
        let screen = Fixture()
        screen.submit.accept(())
        XCTAssertTrue(screen.save.rawURLs.isEmpty)
        XCTAssertTrue(screen.submitHidden)

        screen.selection.accept(rawURL)
        XCTAssertFalse(screen.submitHidden)
        screen.selection.accept(nil)
        screen.submit.accept(())
        XCTAssertTrue(screen.submitHidden)
        XCTAssertTrue(screen.save.rawURLs.isEmpty)
        XCTAssertEqual(screen.savingStates, [false])
        XCTAssertEqual(screen.savedCount, 0)
    }

    func test_pendingSaveBlocksDuplicateSubmitsAndFinishesOnlyAfterSuccess() {
        let screen = Fixture()
        screen.selection.accept(rawURL)
        screen.submit.accept(())
        screen.submit.accept(())
        screen.submit.accept(())

        XCTAssertEqual(screen.save.rawURLs, [rawURL])
        XCTAssertEqual(screen.savingStates, [false, true])
        XCTAssertEqual(screen.savedCount, 0)
        XCTAssertTrue(screen.alerts.isEmpty)

        screen.save.complete(.success(()))
        XCTAssertEqual(screen.savingStates, [false, true, false])
        XCTAssertEqual(screen.savedCount, 1)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_failureClearsLoadingWithoutFinishingAndSameSelectionCanRetry() {
        let screen = Fixture()
        screen.selection.accept(rawURL)
        screen.submit.accept(())
        screen.save.complete(.failure(CocoaError(.fileWriteOutOfSpace)))

        XCTAssertEqual(screen.savingStates, [false, true, false])
        XCTAssertEqual(screen.savedCount, 0)
        XCTAssertEqual(screen.alerts, ["잠시후 다시 시도해주세요"])
        XCTAssertEqual(screen.selection.value, rawURL)
        XCTAssertFalse(screen.submitHidden)

        screen.submit.accept(())
        XCTAssertEqual(screen.save.rawURLs, [rawURL, rawURL])
        XCTAssertEqual(screen.savingStates.last, true)
        XCTAssertEqual(screen.savedCount, 0)
        screen.save.complete(.success(()))
        XCTAssertEqual(screen.savingStates, [false, true, false, true, false])
        XCTAssertEqual(screen.savedCount, 1)
        XCTAssertEqual(screen.alerts.count, 1)
    }

    @MainActor
    private final class Fixture {
        let selection = BehaviorRelay<String?>(value: nil)
        let submit = PublishRelay<Void>()
        let save = ControlledSaveThemeUseCase()
        let viewModel: SearchThemeViewModel
        private let disposeBag = DisposeBag()
        var savingStates: [Bool] = []
        var savedCount = 0
        var alerts: [String] = []
        var submitHidden = true

        init() {
            viewModel = SearchThemeViewModel(searchThemeUseCase: UnusedSearchThemeUseCase(), saveThemeUseCase: save)
            let output = viewModel.transform(input: .init(
                viewWillAppear: .never(), searchText: .never(), loadNextPage: .never(), textEndTrigger: .never(),
                selectedTheme: selection.asObservable(), submitTapped: submit.asObservable()
            ))
            output.isSaving.drive(onNext: { [weak self] in self?.savingStates.append($0) }).disposed(by: disposeBag)
            output.themeSaved.emit(onNext: { [weak self] in self?.savedCount += 1 }).disposed(by: disposeBag)
            output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: disposeBag)
            output.buttonEnable.drive(onNext: { [weak self] in self?.submitHidden = $0 }).disposed(by: disposeBag)
        }
    }
}

private final class ControlledSaveThemeUseCase: SaveThemeUseCase {
    private(set) var rawURLs: [String] = []
    private var pending: ((SingleEvent<Result<Void, Error>>) -> Void)?

    func execute(rawUrl: String) -> Single<Result<Void, Error>> {
        rawURLs.append(rawUrl)
        return Single.create { [self] observer in
            XCTAssertNil(pending, "A pending save must not be replaced by another submit")
            pending = observer
            return Disposables.create()
        }
    }

    func complete(_ result: Result<Void, Error>) {
        guard let observer = pending else {
            XCTFail("No pending save")
            return
        }
        pending = nil
        observer(.success(result))
    }
}

private struct UnusedSearchThemeUseCase: SearchThemeUseCase {
    func execute(query: String, page: Int) async throws -> SearchPhotoEntity {
        XCTFail("Saving a selected theme must not start a search")
        throw URLError(.unsupportedURL)
    }
}
