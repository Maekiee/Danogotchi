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

    func test_failedOnboardingActivationStaysAndNextTapRetries() throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        _ = try books.createBook(title: "travel", bookType: .travel, level: nil)
        let vm = OnboardingInterestViewModel(setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books))
        let next = PublishRelay<Void>()
        let output = vm.transform(input: .init(topicSelected: .just(.travel), nextTapped: next.asObservable()))
        let bag = DisposeBag()
        var finished = 0
        var failures = 0
        output.didFinish.emit(onNext: { finished += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        context.failsSave = true
        next.accept(())
        XCTAssertEqual(finished, 0)
        XCTAssertEqual(failures, 1)
        context.failsSave = false
        next.accept(())
        XCTAssertEqual(finished, 1)
        XCTAssertEqual(try books.readActiveBook()?.bookType, .travel)
    }
}

@MainActor
extension PersistenceViewModelTests {
    func test_failedDeletionKeepsVisibleWordAndRetryRemovesIt() throws {
        let context = makeFailingSaveContext()
        let books = DefaultVocabBookRepository(context: context)
        let book = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let word = try books.addVocab(bookId: book.id, word: "apple", meaning: "사과", bookType: .myBook, level: nil, partOfSpeech: .noun)
        let words = DefaultVocabRepository(context: context)
        let vm = VocabBookDetailViewModel(
            topic: .myBook,
            fetchVocabsUseCase: DefaultFetchVocabsUseCase(vocabBookRepository: books, learningHistoryRepository: DefaultLearningHistoryRepository(context: context)),
            toggleSaveVocabUseCase: DefaultToggleSaveVocabUseCase(vocabBookRepository: books, vocabRepository: words),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: words),
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books),
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
        var ids: [UUID] = []
        var failures = 0
        output.bookItems.drive(onNext: { ids = $0.map(\.id) }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in failures += 1 }).disposed(by: bag)
        let book = VocabBookCardInfo(id: UUID(), topic: .travel, isActive: true)
        useCase.result = .success([book])
        appear.accept(())
        useCase.result = .failure(CocoaError(.fileReadUnknown))
        appear.accept(())
        XCTAssertEqual(ids, [book.id])
        XCTAssertEqual(failures, 1)
        useCase.result = .success([])
        appear.accept(())
        XCTAssertTrue(ids.isEmpty)
    }
}

private final class ControlledBookListUseCase: FetchVocabBooksUseCase {
    var result: Result<[VocabBookCardInfo], Error> = .success([])
    var activeBookChanged: Observable<Void> { .never() }
    func execute() -> Observable<Result<[VocabBookCardInfo], Error>> { .just(result) }
}
