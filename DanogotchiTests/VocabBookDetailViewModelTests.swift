import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class VocabBookDetailViewModelTests: XCTestCase {
    func test_appearLoadsBookWordsAndActiveState() throws {
        let screen = try BookDetailTestScreen(topic: .travel)
        screen.appear.accept(())
        XCTAssertEqual(screen.words.map(\.word.word), ["airport", "depart"])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertEqual(screen.isActive, false)

        try screen.books.setActiveBook(id: screen.travel.id)
        screen.appear.accept(())
        XCTAssertEqual(screen.isActive, true)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_startLearningActivatesBookInPlace() throws {
        let screen = try BookDetailTestScreen(topic: .travel)
        screen.appear.accept(())
        screen.startLearning.accept(())
        XCTAssertEqual(screen.isActive, true)
        XCTAssertEqual(try screen.books.readActiveBook()?.id, screen.travel.id)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_startLearningFailureAlertsAndKeepsInactive() throws {
        let screen = try BookDetailTestScreen(topic: .travel)
        screen.appear.accept(())
        screen.context.failsSave = true
        screen.startLearning.accept(())
        XCTAssertEqual(screen.isActive, false)
        XCTAssertEqual(screen.alerts, [String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요.")])
        XCTAssertNil(try screen.books.readActiveBook())
    }

    func test_saveToggleUpdatesOnlyThatWordAndPersists() throws {
        let screen = try BookDetailTestScreen(topic: .travel)
        screen.appear.accept(())
        let airport = screen.words[0]

        screen.save.accept(airport)
        XCTAssertEqual(screen.words.map(\.isSaved), [true, false])
        XCTAssertNotNil(try screen.books.findVocab(inBookId: screen.myBook.id, sourceWordId: airport.word.id))

        screen.save.accept(screen.words[0])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertNil(try screen.books.findVocab(inBookId: screen.myBook.id, sourceWordId: airport.word.id))
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_saveFailureAlertsAndLeavesListUnchanged() throws {
        let screen = try BookDetailTestScreen(topic: .travel)
        screen.appear.accept(())
        screen.context.failsSave = true
        screen.save.accept(screen.words[0])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertEqual(screen.alerts, [String(localized: "저장하지 못했어요. 다시 시도해주세요.")])
    }
}

/// 실제 유스케이스를 인메모리 Core Data에 올린다 — 여행 단어장 2단어 + 빈 나의 단어장
@MainActor
private final class BookDetailTestScreen {
    let context = makeFailingSaveContext()
    let books: DefaultVocabBookRepository
    let travel: VocabBook
    let myBook: VocabBook
    let appear = PublishRelay<Void>()
    let save = PublishRelay<VocabDisplayInfo>()
    let delete = PublishRelay<Vocab>()
    let startLearning = PublishRelay<Void>()
    private(set) var words: [VocabDisplayInfo] = []
    private(set) var isActive: Bool?
    private(set) var alerts: [String] = []
    private let viewModel: VocabBookDetailViewModel
    private let bag = DisposeBag()

    init(topic: BookTopic) throws {
        books = DefaultVocabBookRepository(context: context)
        myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        travel = try books.createBook(title: "travel", bookType: .travel, level: .a1)
        _ = try books.addVocab(bookId: travel.id, word: "airport", meaning: "공항", bookType: .travel, level: .a1, partOfSpeech: .noun)
        _ = try books.addVocab(bookId: travel.id, word: "depart", meaning: "출발하다", bookType: .travel, level: .a1, partOfSpeech: .verb)
        let wordsRepository = DefaultVocabRepository(context: context)
        viewModel = VocabBookDetailViewModel(
            topic: topic,
            fetchVocabsUseCase: DefaultFetchVocabsUseCase(vocabBookRepository: books,
                                                          learningHistoryRepository: DefaultLearningHistoryRepository(context: context)),
            toggleSaveVocabUseCase: DefaultToggleSaveVocabUseCase(vocabBookRepository: books, vocabRepository: wordsRepository),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: wordsRepository),
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books),
            isActiveBookUseCase: DefaultIsActiveBookUseCase(vocabBookRepository: books)
        )
        let output = viewModel.transform(input: .init(
            viewWillAppear: appear.asObservable(), saveVocabTrigger: save.asObservable(),
            deleteVocabTrigger: delete.asObservable(), startLearningTrigger: startLearning.asObservable()
        ))
        output.vocabList.drive(onNext: { [weak self] in self?.words = $0 }).disposed(by: bag)
        output.isActiveBook.drive(onNext: { [weak self] in self?.isActive = $0 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
