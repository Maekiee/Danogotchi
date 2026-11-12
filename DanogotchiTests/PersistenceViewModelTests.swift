import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class PersistenceViewModelTests: XCTestCase {
    func test_addFailureKeepsFormAndRetryClearsItOnlyAfterSave() throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let vm = AddVocabViewModel(addVocabUseCase: DefaultAddVocabUseCase(vocabBookRepository: books),
                                  updateVocabUseCase: DefaultUpdateVocabUseCase(vocabRepository: DefaultVocabRepository(context: context)))
        let save = PublishRelay<Void>()
        let output = vm.transform(input: .init(wordTextField: .just("apple"), meaningTextField: .just("사과"),
                                               partOfSpeechSegment: .just(0), savedButtonTapped: save.asObservable()))
        let bag = DisposeBag()
        var resets = 0
        var failures = 0
        var valid = false
        output.resetTrigger.emit(onNext: { resets += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        output.isValidSave.drive(onNext: { valid = $0 }).disposed(by: bag)
        context.failsSave = true
        save.accept(())
        XCTAssertEqual(resets, 0)
        XCTAssertEqual(failures, 1)
        XCTAssertTrue(valid)
        XCTAssertTrue(try books.fetchVocabs(inBookId: book.id).isEmpty)

        context.failsSave = false
        save.accept(())
        XCTAssertEqual(resets, 1)
        XCTAssertFalse(valid)
        XCTAssertEqual(try books.fetchVocabs(inBookId: book.id).map(\.word), ["apple"])
    }

    func test_editFailureDoesNotFinishAndSameInputCanRetry() throws {
        let context = makeFailingSaveContext()
        let words = DefaultVocabRepository(context: context)
        let word = try words.createVocab(vocab: "old", meaning: "뜻")
        let vm = AddVocabViewModel(addVocabUseCase: DefaultAddVocabUseCase(vocabBookRepository: DefaultVocabBookRepository(context: context)),
                                  updateVocabUseCase: DefaultUpdateVocabUseCase(vocabRepository: words), editingVocab: word)
        let save = PublishRelay<Void>()
        let output = vm.transform(input: .init(wordTextField: .just("new"), meaningTextField: .just("뜻"),
                                               partOfSpeechSegment: .just(0), savedButtonTapped: save.asObservable()))
        let bag = DisposeBag()
        var completed = 0
        output.editCompleted.emit(onNext: { completed += 1 }).disposed(by: bag)
        context.failsSave = true
        save.accept(())
        XCTAssertEqual(completed, 0)
        XCTAssertEqual(try words.readVocab(id: word.id)?.word, "old")
        context.failsSave = false
        save.accept(())
        XCTAssertEqual(completed, 1)
        XCTAssertEqual(try words.readVocab(id: word.id)?.word, "new")
    }

    func test_failedOnboardingActivationStaysAndNextTapRetries() async throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        // 이미 받은 기존 설치본 — 저장 실패만 본다
        _ = try books.createBook(title: "travel", bookType: .travel, level: .a1)
        let remote = ControlledRemoteVocabBookRepository()
        let vm = OnboardingInterestViewModel(selectInterestUseCase: DefaultSelectInterestUseCase(
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            vocabBookRepository: books
        ))
        let next = PublishRelay<Void>()
        let output = vm.transform(input: .init(topicSelected: .just(.travel), nextTapped: next.asObservable()))
        let bag = DisposeBag()
        var finished = 0
        var failures = 0
        output.didFinish.emit(onNext: { finished += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        context.failsSave = true
        next.accept(())
        await waitUntil { failures == 1 }
        XCTAssertEqual(finished, 0)
        context.failsSave = false
        next.accept(())
        await waitUntil { finished == 1 }
        XCTAssertEqual(failures, 1)
        XCTAssertEqual(try books.readActiveBooks().map(\.key), [travelA1])
        XCTAssertTrue(remote.fetchedKeys.isEmpty)
    }
}

@MainActor
extension PersistenceViewModelTests {
    func test_failedDeletionKeepsVisibleWordAndRetryRemovesIt() async throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let word = try books.addVocab(bookId: book.id, word: "apple", meaning: "사과", bookType: .myBook, level: nil, partOfSpeech: .noun)
        let words = DefaultVocabRepository(context: context)
        let remote = ControlledRemoteVocabBookRepository()
        let vm = VocabBookDetailViewModel(
            key: VocabBookKey(topic: .myBook, level: nil),
            fetchVocabsUseCase: DefaultFetchVocabsUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote,
                                                          learningHistoryRepository: DefaultLearningHistoryRepository(context: context)),
            toggleSaveVocabUseCase: DefaultToggleSaveVocabUseCase(vocabBookRepository: books, vocabRepository: words),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: words),
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            isActiveBookUseCase: DefaultIsActiveBookUseCase(vocabBookRepository: books)
        )
        let appear = PublishRelay<Void>()
        let delete = PublishRelay<Vocab>()
        let output = vm.transform(input: .init(viewWillAppear: appear.asObservable(), saveVocabTrigger: .never(),
                                               deleteVocabTrigger: delete.asObservable(), startLearningTrigger: .never()))
        let bag = DisposeBag()
        var ids: [UUID] = []
        var failures = 0
        output.vocabList.drive(onNext: { ids = $0.map { $0.word.id } }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        appear.accept(())
        await waitUntil { !ids.isEmpty }
        context.failsSave = true
        delete.accept(word)
        XCTAssertEqual(ids, [word.id])
        XCTAssertEqual(failures, 1)
        context.failsSave = false
        delete.accept(word)
        XCTAssertTrue(ids.isEmpty)
    }

    func test_readFailureKeepsPreviousLibraryAndNextRefreshStillWorks() {
        let useCase = ControlledBookListUseCase()
        let vm = LibraryViewModel(fetchVocabBooksUseCase: useCase)
        let appear = PublishRelay<Void>()
        let output = vm.transform(input: .init(viewWillAppear: appear.asObservable()))
        let bag = DisposeBag()
        var keys: [VocabBookKey] = []
        var failures = 0
        output.bookItems.drive(onNext: { keys = $0.map(\.key) }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        let book = VocabBookCardInfo(key: travelA1, isActive: true)
        useCase.result = .success([book])
        appear.accept(())
        useCase.result = .failure(CocoaError(.fileReadUnknown))
        appear.accept(())
        XCTAssertEqual(keys, [book.key])
        XCTAssertEqual(failures, 1)
        useCase.result = .success([])
        appear.accept(())
        XCTAssertTrue(keys.isEmpty)
    }

    func test_libraryRefreshesOnMainWhenActiveBookChangesElsewhere() async throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())
        let travel = try books.createBook(title: "travel", bookType: .travel, level: .a1)
        let life = try books.createBook(title: "life", bookType: .life, level: .a1)
        try books.setActive(id: travel.id, isActive: true)
        let vm = LibraryViewModel(fetchVocabBooksUseCase: DefaultFetchVocabBooksUseCase(
            vocabBookRepository: books, remoteVocabBookRepository: ControlledRemoteVocabBookRepository()
        ))
        let appear = PublishRelay<Void>()
        let output = vm.transform(input: .init(viewWillAppear: appear.asObservable()))
        let bag = DisposeBag()
        let refreshed = expectation(description: "activation from another screen refreshes the library")
        // 서버 목록 도착도 같은 목록을 다시 그린다
        refreshed.assertForOverFulfill = false
        output.bookItems.drive(onNext: { items in
            guard items.contains(VocabBookCardInfo(key: life.key, isActive: true)) else { return }
            XCTAssertTrue(Thread.isMainThread)
            refreshed.fulfill()
        }).disposed(by: bag)
        appear.accept(())

        // 단어장 상세 화면이 학습 단어장을 추가한 상황
        try books.setActive(id: life.id, isActive: true)

        await fulfillment(of: [refreshed], timeout: 2)
    }
}

private final class ControlledBookListUseCase: FetchVocabBooksUseCase {
    var result: Result<[VocabBookCardInfo], Error> = .success([])
    var activeBookChanged: AsyncStream<Void> { AsyncStream { _ in } }
    func fetchRemoteBooks() async throws -> [RemoteVocabBook] { [] }
    func execute(remoteBooks: [RemoteVocabBook]) throws -> [VocabBookCardInfo] { try result.get() }
}
