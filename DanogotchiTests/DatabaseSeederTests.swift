import CoreData
import XCTest
@testable import Danogotchi

final class DatabaseSeederTests: XCTestCase {
    func test_seedsOnlyEmptyMyBookAndIsIdempotent() throws {
        let context = makeInMemoryContext()

        try DatabaseSeeder.seedIfNeeded(context: context)
        try DatabaseSeeder.seedIfNeeded(context: context)

        let books = try DefaultVocabBookRepository(context: context).readAllBooks()
        XCTAssertEqual(books.map(\.bookType), [.myBook])
        XCTAssertEqual(books.first?.isActive, false)
        XCTAssertEqual(try context.count(for: VocabEntity.fetchRequest()), 0)
    }

    func test_existingBooksSkipSeeding() throws {
        let context = makeInMemoryContext()
        // 기존 설치본 — 추천 단어장이 이미 있으면 나의 단어장을 다시 만들지 않는다
        _ = try DefaultVocabBookRepository(context: context).createBook(title: "Travel", bookType: .travel, level: .a1)

        try DatabaseSeeder.seedIfNeeded(context: context)

        XCTAssertEqual(try DefaultVocabBookRepository(context: context).readAllBooks().map(\.bookType), [.travel])
    }
}
