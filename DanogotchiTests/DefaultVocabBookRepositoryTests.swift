import XCTest
@testable import Danogotchi

final class DefaultVocabBookRepositoryTests: XCTestCase {
    func test_readBookSummariesReturnsKeyAndActiveStateInCreationOrder() throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())
        let myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let travel = try books.importBook(key: travelA1, vocabs: makeServerVocabs(travelA1, words: ["airport"]), isActive: true)

        let summaries = try books.readBookSummaries()

        XCTAssertEqual(summaries.map(\.id), [myBook.id, travel.id])
        XCTAssertEqual(summaries.map(\.key), [VocabBookKey(topic: .myBook, level: nil), travelA1])
        XCTAssertEqual(summaries.map(\.isActive), [false, true])
    }

    func test_importBookUsesTopicTitleLikeExistingInstalls() throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())

        let travel = try books.importBook(key: travelA1, vocabs: [], isActive: false)

        XCTAssertEqual(travel.title, "Travel")
    }
}
