import CoreData
import XCTest
@testable import Danogotchi

final class DatabaseSeederTests: XCTestCase {
    func test_seedsMeaningsInAppLanguage() throws {
        let japanese = makeInMemoryContext()
        try DatabaseSeeder.seedIfNeeded(context: japanese, language: "ja")
        XCTAssertEqual(try firstBusinessMeaning(in: japanese), MockBusinessWordsJa.data[0].1)

        let korean = makeInMemoryContext()
        try DatabaseSeeder.seedIfNeeded(context: korean, language: "ko")
        XCTAssertEqual(try firstBusinessMeaning(in: korean), MockBusinessWords.data[0].1)

        // 지원하지 않는 언어는 한국어 뜻으로 시드
        let other = makeInMemoryContext()
        try DatabaseSeeder.seedIfNeeded(context: other, language: "fr")
        XCTAssertEqual(try firstBusinessMeaning(in: other), MockBusinessWords.data[0].1)
        XCTAssertEqual(try other.count(for: VocabEntity.fetchRequest()), 1457)
    }

    private func firstBusinessMeaning(in context: NSManagedObjectContext) throws -> String? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "word == %@ AND bookType == %@", MockBusinessWords.data[0].0, BookTopic.business.rawValue
        )
        return try context.fetch(request).first?.meaning
    }
}
