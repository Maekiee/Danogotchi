import RxSwift
import XCTest
@testable import Danogotchi

final class VocabUseCaseTests: XCTestCase {

    func test_executeActive는_활성_추천단어장에_이력과_저장상태를_합친다() throws {
        let sut = makeSUT()
        let myBook = sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let travelBook = sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let savedWord = try XCTUnwrap(
            sut.books.addVocab(
                bookId: travelBook.id,
                word: "airport",
                meaning: "공항",
                bookType: .travel,
                level: .a1,
                partOfSpeech: .noun
            )
        )
        let unsavedWord = try XCTUnwrap(
            sut.books.addVocab(
                bookId: travelBook.id,
                word: "depart",
                meaning: "출발하다",
                bookType: .travel,
                level: .a1,
                partOfSpeech: .verb
            )
        )
        XCTAssertNotNil(sut.books.addVocab(bookId: myBook.id, from: savedWord))
        sut.histories.addHistory(vocabId: savedWord.id, isCorrect: true)
        sut.histories.addHistory(vocabId: savedWord.id, isCorrect: false)
        sut.books.setActiveBook(id: travelBook.id)

        var received: (bookType: BookTopic, items: [VocabDisplayInfo])?
        _ = sut.useCase.executeActive().subscribe(onNext: { received = $0 })

        let content = try XCTUnwrap(received)
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

    func test_executeActive는_활성단어장이_없으면_값을_방출하지_않는다() {
        let sut = makeSUT()
        var didEmit = false
        var didComplete = false

        _ = sut.useCase.executeActive().subscribe(
            onNext: { _ in didEmit = true },
            onCompleted: { didComplete = true }
        )

        XCTAssertFalse(didEmit)
        XCTAssertTrue(didComplete)
    }

    func test_activeBookChanged는_활성단어장_변경을_전달한다() {
        let sut = makeSUT()
        let book = sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        var changeCount = 0
        let disposable = sut.useCase.activeBookChanged
            .skip(1)
            .subscribe(onNext: { _ in changeCount += 1 })

        sut.books.setActiveBook(id: book.id)

        XCTAssertEqual(changeCount, 1)
        disposable.dispose()
    }

    private func makeSUT() -> (
        useCase: DefaultFetchVocabsUseCase,
        books: DefaultVocabBookRepository,
        histories: DefaultLearningHistoryRepository
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
            histories: histories
        )
    }
}
