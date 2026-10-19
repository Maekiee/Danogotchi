import XCTest
@testable import Danogotchi

final class VocabUseCaseTests: XCTestCase {

    func test_executeActive는_활성_추천단어장에_이력과_저장상태를_합친다() throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let travelBook = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let savedWord = try sut.books.addVocab(
            bookId: travelBook.id,
            word: "airport",
            meaning: "공항",
            bookType: .travel,
            level: .a1,
            partOfSpeech: .noun
        )
        let unsavedWord = try sut.books.addVocab(
            bookId: travelBook.id,
            word: "depart",
            meaning: "출발하다",
            bookType: .travel,
            level: .a1,
            partOfSpeech: .verb
        )
        _ = try sut.books.addVocab(bookId: myBook.id, from: savedWord)
        try sut.histories.addHistory(makeQuizAnswer(savedWord))
        try sut.histories.addHistory(makeQuizAnswer(savedWord, isCorrect: false))
        try sut.books.setActiveBook(id: travelBook.id)

        let content = try XCTUnwrap(sut.useCase.executeActive())
        let itemsById = Dictionary(uniqueKeysWithValues: content.items.map { ($0.word.id, $0) })
        let savedItem = try XCTUnwrap(itemsById[savedWord.id])
        let unsavedItem = try XCTUnwrap(itemsById[unsavedWord.id])

        XCTAssertEqual(content.bookType, .travel)
        XCTAssertEqual(content.items.count, 2)
        XCTAssertEqual(savedItem.learningCount, 2)
        XCTAssertEqual(savedItem.accuracy, 0.5, accuracy: 0.001)
        XCTAssertTrue(savedItem.isSaved)
        XCTAssertEqual(unsavedItem.learningCount, 0)
        XCTAssertFalse(unsavedItem.isSaved)
    }

    func test_executeActive는_활성단어장이_없으면_nil을_반환한다() throws {
        XCTAssertNil(try makeSUT().useCase.executeActive())
    }

    func test_isActiveBook은_활성단어장일때만_true다() throws {
        let sut = makeSUT()
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        _ = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)
        try sut.books.setActiveBook(id: travel.id)
        let useCase = DefaultIsActiveBookUseCase(vocabBookRepository: sut.books)

        XCTAssertTrue(try useCase.execute(topic: .travel))
        XCTAssertFalse(try useCase.execute(topic: .emotion))
        XCTAssertFalse(try useCase.execute(topic: .life))
    }

    func test_setActiveBook은_지정한_단어장을_활성화한다() throws {
        let sut = makeSUT()
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let emotion = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)
        try sut.books.setActiveBook(id: travel.id)

        try DefaultSetActiveBookUseCase(vocabBookRepository: sut.books).execute(topic: .emotion)

        XCTAssertEqual(try sut.books.readActiveBook()?.id, emotion.id)
    }

    func test_setActiveBook은_단어장이_없으면_entityNotFound를_던진다() {
        let useCase = DefaultSetActiveBookUseCase(vocabBookRepository: makeSUT().books)

        XCTAssertThrowsError(try useCase.execute(topic: .travel)) { error in
            XCTAssertEqual(error as? PersistenceError, .entityNotFound)
        }
    }

    func test_toggleSaveVocab은_저장과_해제를_번갈아_한다() throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let word = try addTravelWord(to: sut.books)
        let useCase = DefaultToggleSaveVocabUseCase(vocabBookRepository: sut.books, vocabRepository: sut.words)

        XCTAssertTrue(try useCase.execute(vocab: word))
        XCTAssertEqual(try sut.books.findVocab(inBookId: myBook.id, sourceWordId: word.id)?.word, word.word)

        XCTAssertFalse(try useCase.execute(vocab: word))
        XCTAssertNil(try sut.books.findVocab(inBookId: myBook.id, sourceWordId: word.id))
    }

    func test_toggleSaveVocab은_나의_단어장이_없으면_entityNotFound를_던진다() throws {
        let sut = makeSUT()
        let word = try addTravelWord(to: sut.books)
        let useCase = DefaultToggleSaveVocabUseCase(vocabBookRepository: sut.books, vocabRepository: sut.words)

        XCTAssertThrowsError(try useCase.execute(vocab: word)) { error in
            XCTAssertEqual(error as? PersistenceError, .entityNotFound)
        }
    }

    func test_fetchVocabBooks는_활성단어장만_isActive로_표시한다() throws {
        let sut = makeSUT()
        _ = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let emotion = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)
        try sut.books.setActiveBook(id: emotion.id)

        let cards = try DefaultFetchVocabBooksUseCase(vocabBookRepository: sut.books).execute()

        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(cards.filter(\.isActive).map(\.id), [emotion.id])
    }

    @MainActor
    func test_activeBookChanged는_활성단어장_변경을_전달한다() async throws {
        let sut = makeSUT()
        let book = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        // 변경 전에 구독을 등록한다
        var changes = sut.useCase.activeBookChanged.makeAsyncIterator()

        try sut.books.setActiveBook(id: book.id)

        let received: Void? = await changes.next()
        XCTAssertNotNil(received)
    }

    private func makeSUT() -> (
        useCase: DefaultFetchVocabsUseCase,
        books: DefaultVocabBookRepository,
        histories: DefaultLearningHistoryRepository,
        words: DefaultVocabRepository
    ) {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let histories = DefaultLearningHistoryRepository(context: context)
        return (
            useCase: DefaultFetchVocabsUseCase(
                vocabBookRepository: books,
                learningHistoryRepository: histories
            ),
            books: books,
            histories: histories,
            words: DefaultVocabRepository(context: context)
        )
    }

    private func addTravelWord(to books: DefaultVocabBookRepository) throws -> Vocab {
        let travel = try books.createBook(title: "여행", bookType: .travel, level: .a1)
        return try books.addVocab(bookId: travel.id, word: "airport", meaning: "공항",
                                  bookType: .travel, level: .a1, partOfSpeech: .noun)
    }
}
