import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class VocabBookDetailViewModelTests: XCTestCase {
    func test_appearLoadsBookWordsAndActiveState() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        screen.appear.accept(())
        await waitUntil { !screen.words.isEmpty }
        XCTAssertEqual(screen.words.map(\.word.word), ["airport", "depart"])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertEqual(screen.isActive, false)

        try screen.books.setActive(id: screen.travel.id, isActive: true)
        screen.appear.accept(())
        XCTAssertEqual(screen.isActive, true)
        XCTAssertTrue(screen.alerts.isEmpty)
        XCTAssertTrue(screen.remote.fetchedKeys.isEmpty)
    }

    func test_startLearningActivatesBookInPlace() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        screen.appear.accept(())
        screen.startLearning.accept(())
        XCTAssertEqual(screen.isLoading, true)
        await waitUntil { screen.isLoading == false }
        XCTAssertEqual(screen.isActive, true)
        XCTAssertEqual(try screen.books.readActiveBooks().map(\.id), [screen.travel.id])
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_tappingLearningAgainTurnsOffAndKeepsWords() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        try screen.books.setActive(id: screen.myBook.id, isActive: true)
        try screen.books.setActive(id: screen.travel.id, isActive: true)
        screen.appear.accept(())
        XCTAssertEqual(screen.isActive, true)

        screen.startLearning.accept(())
        await waitUntil { screen.isLoading == false }

        XCTAssertEqual(screen.isActive, false)
        // 다른 학습중 단어장은 그대로, 끈 단어장의 단어는 남는다
        XCTAssertEqual(try screen.books.readActiveBooks().map(\.id), [screen.myBook.id])
        XCTAssertEqual(try screen.books.fetchVocabs(inBookId: screen.travel.id).count, 2)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_startLearningFailureAlertsAndKeepsInactive() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        screen.appear.accept(())
        screen.context.failsSave = true
        screen.startLearning.accept(())
        await waitUntil { screen.isLoading == false }
        XCTAssertEqual(screen.isActive, false)
        XCTAssertEqual(screen.alerts, [String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요.")])
        XCTAssertTrue(try screen.books.readActiveBooks().isEmpty)
    }

    func test_notDownloadedBookReadsServerOnceThroughReappearAndStartLearning() async throws {
        let screen = try BookDetailTestScreen(key: businessA1)
        let serverWords = makeServerVocabs(businessA1, words: ["meeting", "invoice"])
        screen.remote.vocabs[businessA1] = serverWords

        screen.appear.accept(())
        XCTAssertEqual(screen.isLoadingWords, true)
        await waitUntil { !screen.words.isEmpty }
        XCTAssertEqual(screen.isLoadingWords, false)
        XCTAssertEqual(screen.words.map(\.word.id), serverWords.map(\.id))
        XCTAssertEqual(screen.isActive, false)
        XCTAssertNil(try screen.books.readBookSummary(key: businessA1))

        // 다시 나타나도 받아 둔 단어를 쓴다
        screen.appear.accept(())
        await waitUntil { screen.isLoadingWords == false }
        XCTAssertEqual(screen.words.map(\.word.id), serverWords.map(\.id))

        screen.startLearning.accept(())
        await waitUntil { screen.isLoading == false }
        XCTAssertEqual(screen.isActive, true)
        let book = try XCTUnwrap(screen.books.readBookSummary(key: businessA1))
        XCTAssertEqual(try screen.books.fetchVocabs(inBookId: book.id).map(\.id), serverWords.map(\.id))
        XCTAssertEqual(screen.remote.fetchedKeys, [businessA1])
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_serverReadFailureAlerts() async throws {
        let screen = try BookDetailTestScreen(key: businessA1)
        screen.remote.vocabsError = URLError(.notConnectedToInternet)

        screen.appear.accept(())
        await waitUntil { !screen.alerts.isEmpty }

        XCTAssertTrue(screen.words.isEmpty)
        XCTAssertEqual(screen.alerts.first, String(localized: "단어를 불러오지 못했어요. 다시 시도해주세요."))
    }

    func test_saveToggleUpdatesOnlyThatWordAndPersists() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        screen.appear.accept(())
        await waitUntil { !screen.words.isEmpty }
        let airport = screen.words[0]

        screen.save.accept(airport)
        XCTAssertEqual(screen.words.map(\.isSaved), [true, false])
        XCTAssertNotNil(try screen.books.findVocab(inBookId: screen.myBook.id, sourceWordId: airport.word.id))

        screen.save.accept(screen.words[0])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertNil(try screen.books.findVocab(inBookId: screen.myBook.id, sourceWordId: airport.word.id))
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_saveFailureAlertsAndLeavesListUnchanged() async throws {
        let screen = try BookDetailTestScreen(key: travelA1)
        screen.appear.accept(())
        await waitUntil { !screen.words.isEmpty }
        screen.context.failsSave = true
        screen.save.accept(screen.words[0])
        XCTAssertEqual(screen.words.map(\.isSaved), [false, false])
        XCTAssertEqual(screen.alerts, [String(localized: "저장하지 못했어요. 다시 시도해주세요.")])
    }
}

/// 실제 유스케이스를 인메모리 Core Data에 올린다 — 받은 여행 단어장 2단어 + 빈 나의 단어장, 원격은 대역
@MainActor
private final class BookDetailTestScreen {
    let context = makeFailingSaveContext()
    let books: DefaultVocabBookRepository
    let remote = ControlledRemoteVocabBookRepository()
    let travel: VocabBook
    let myBook: VocabBook
    let appear = PublishRelay<Void>()
    let save = PublishRelay<VocabDisplayInfo>()
    let delete = PublishRelay<Vocab>()
    let startLearning = PublishRelay<Void>()
    private(set) var words: [VocabDisplayInfo] = []
    private(set) var isActive: Bool?
    private(set) var isLoadingWords: Bool?
    private(set) var isLoading: Bool?
    private(set) var alerts: [String] = []
    private let viewModel: VocabBookDetailViewModel
    private let bag = DisposeBag()

    init(key: VocabBookKey) throws {
        books = DefaultVocabBookRepository(context: context)
        myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        travel = try books.createBook(title: "travel", bookType: .travel, level: .a1)
        _ = try books.addVocab(bookId: travel.id, word: "airport", meaning: "공항", bookType: .travel, level: .a1, partOfSpeech: .noun)
        _ = try books.addVocab(bookId: travel.id, word: "depart", meaning: "출발하다", bookType: .travel, level: .a1, partOfSpeech: .verb)
        let wordsRepository = DefaultVocabRepository(context: context)
        viewModel = VocabBookDetailViewModel(
            key: key,
            fetchVocabsUseCase: DefaultFetchVocabsUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote,
                                                          learningHistoryRepository: DefaultLearningHistoryRepository(context: context)),
            toggleSaveVocabUseCase: DefaultToggleSaveVocabUseCase(vocabBookRepository: books, vocabRepository: wordsRepository),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: wordsRepository),
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            isActiveBookUseCase: DefaultIsActiveBookUseCase(vocabBookRepository: books)
        )
        let output = viewModel.transform(input: .init(
            viewWillAppear: appear.asObservable(), saveVocabTrigger: save.asObservable(),
            deleteVocabTrigger: delete.asObservable(), startLearningTrigger: startLearning.asObservable()
        ))
        output.vocabList.drive(onNext: { [weak self] in self?.words = $0 }).disposed(by: bag)
        output.isActiveBook.drive(onNext: { [weak self] in self?.isActive = $0 }).disposed(by: bag)
        output.isLoadingWords.drive(onNext: { [weak self] in self?.isLoadingWords = $0 }).disposed(by: bag)
        output.isLoading.drive(onNext: { [weak self] in self?.isLoading = $0 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
