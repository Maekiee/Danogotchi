import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class AddVocabViewModelTests: XCTestCase {
    func test_saveIsEnabledOnlyWhenTrimmedWordAndMeaningAreNonEmpty() throws {
        let screen = try AddVocabTestScreen()
        XCTAssertEqual(screen.isValid, false)

        screen.word.accept("  apple ")
        XCTAssertEqual(screen.isValid, false)
        screen.meaning.accept("   ")
        XCTAssertEqual(screen.isValid, false)
        screen.meaning.accept(" 사과 ")
        XCTAssertEqual(screen.isValid, true)
        screen.word.accept("\n")
        XCTAssertEqual(screen.isValid, false)
    }

    func test_initialFormIsNilForAddAndMirrorsEditingVocab() throws {
        XCTAssertNil(try AddVocabTestScreen().initialForm)
        XCTAssertFalse(try AddVocabTestScreen().isEditing)

        let adjective = makeVocab(word: "quick", meaning: "빠른", partOfSpeech: .adj)
        let editing = try AddVocabTestScreen(editing: adjective)
        XCTAssertTrue(editing.isEditing)
        XCTAssertEqual(editing.initialForm?.word, "quick")
        XCTAssertEqual(editing.initialForm?.meaning, "빠른")
        XCTAssertEqual(editing.initialForm?.partOfSpeechIndex, PartOfSpeech.allCases.firstIndex(of: .adj))

        // 품사 정보가 없으면 첫 세그먼트로 떨어진다
        let untyped = try AddVocabTestScreen(editing: makeVocab(word: "x", meaning: "y", partOfSpeech: nil))
        XCTAssertEqual(untyped.initialForm?.partOfSpeechIndex, 0)
    }

    func test_trimmedValuesAndSelectedPartOfSpeechAreSaved() throws {
        let screen = try AddVocabTestScreen()
        screen.word.accept(" apple ")
        screen.meaning.accept(" 사과 ")
        screen.segment.accept(try XCTUnwrap(PartOfSpeech.allCases.firstIndex(of: .adv)))

        screen.save.accept(())

        let saved = try screen.books.fetchVocabs(inBookId: screen.myBook.id)
        XCTAssertEqual(saved.map(\.word), ["apple"])
        XCTAssertEqual(saved.first?.meaning, "사과")
        XCTAssertEqual(saved.first?.partOfSpeech, .adv)
        XCTAssertEqual(screen.resets, 1)
        XCTAssertEqual(screen.isValid, false)
    }

    private func makeVocab(word: String, meaning: String, partOfSpeech: PartOfSpeech?) -> Vocab {
        Vocab(id: UUID(), word: word, meaning: meaning, bookType: .myBook, level: nil,
              partOfSpeech: partOfSpeech, sourceWordId: nil, createAt: testBase)
    }
}

@MainActor
private final class AddVocabTestScreen {
    let books: DefaultVocabBookRepository
    let myBook: VocabBook
    let word = PublishRelay<String>()
    let meaning = PublishRelay<String>()
    let segment = PublishRelay<Int>()
    let save = PublishRelay<Void>()
    private(set) var isValid: Bool?
    private(set) var resets = 0
    private let viewModel: AddVocabViewModel
    private let bag = DisposeBag()

    var initialForm: (word: String, meaning: String, partOfSpeechIndex: Int)? { viewModel.initialForm }
    var isEditing: Bool { viewModel.isEditing }

    init(editing: Vocab? = nil) throws {
        let context = makeInMemoryContext()
        books = DefaultVocabBookRepository(context: context)
        myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        viewModel = AddVocabViewModel(
            addVocabUseCase: DefaultAddVocabUseCase(vocabBookRepository: books),
            updateVocabUseCase: DefaultUpdateVocabUseCase(vocabRepository: DefaultVocabRepository(context: context)),
            editingVocab: editing
        )
        let output = viewModel.transform(input: .init(
            wordTextField: word.asObservable(), meaningTextField: meaning.asObservable(),
            partOfSpeechSegment: segment.asObservable(), savedButtonTapped: save.asObservable()
        ))
        output.isValidSave.drive(onNext: { [weak self] in self?.isValid = $0 }).disposed(by: bag)
        output.resetTrigger.emit(onNext: { [weak self] in self?.resets += 1 }).disposed(by: bag)
    }
}
