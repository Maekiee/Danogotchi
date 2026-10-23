import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class OnboardingInterestViewModelTests: XCTestCase {
    func test_interestCardsExcludeMyBookAndStartUnselected() throws {
        let screen = try InterestTestScreen()
        XCTAssertEqual(screen.items.map(\.topic), BookTopic.allCases.filter { $0 != .myBook })
        XCTAssertFalse(screen.items.contains(where: \.isSelected))
        XCTAssertEqual(screen.isNextEnabled, false)
    }

    func test_selectionMarksOneCardAndReselectingKeepsIt() throws {
        let screen = try InterestTestScreen()
        screen.select.accept(.travel)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.travel])
        XCTAssertEqual(screen.isNextEnabled, true)

        screen.select.accept(.travel)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.travel])

        screen.select.accept(.life)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.life])
    }

    func test_nextWithoutSelectionDoesNothing() throws {
        let screen = try InterestTestScreen()
        screen.next.accept(())
        XCTAssertEqual(screen.finished, 0)
        XCTAssertNil(try screen.books.readActiveBook())
    }

    func test_nextActivatesSelectedBookAndFinishes() throws {
        let screen = try InterestTestScreen()
        screen.select.accept(.life)
        screen.next.accept(())
        XCTAssertEqual(screen.finished, 1)
        XCTAssertTrue(screen.alerts.isEmpty)
        XCTAssertEqual(try screen.books.readActiveBook()?.bookType, .life)
    }
}

@MainActor
private final class InterestTestScreen {
    let books: DefaultVocabBookRepository
    let select = PublishRelay<BookTopic>()
    let next = PublishRelay<Void>()
    private(set) var items: [OnboardingInterestItem] = []
    private(set) var isNextEnabled: Bool?
    private(set) var finished = 0
    private(set) var alerts: [String] = []
    private let viewModel: OnboardingInterestViewModel
    private let bag = DisposeBag()

    init() throws {
        let context = makeInMemoryContext()
        books = DefaultVocabBookRepository(context: context)
        // 시드와 같은 다섯 단어장 — 어떤 관심사를 골라도 활성화 대상이 있다
        try DatabaseSeeder.seedIfNeeded(context: context, language: "ko")
        viewModel = OnboardingInterestViewModel(setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books))
        let output = viewModel.transform(input: .init(topicSelected: select.asObservable(), nextTapped: next.asObservable()))
        output.interestItems.drive(onNext: { [weak self] in self?.items = $0 }).disposed(by: bag)
        output.isNextEnabled.drive(onNext: { [weak self] in self?.isNextEnabled = $0 }).disposed(by: bag)
        output.didFinish.emit(onNext: { [weak self] in self?.finished += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
