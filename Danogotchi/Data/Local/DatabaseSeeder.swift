import Foundation
import CoreData

/// 최초 실행 시 나의 단어장을 CoreData에 시드. 추천 단어장은 온보딩·학습하기에서 서버에서 받는다
enum DatabaseSeeder {
    static func seedIfNeeded(context: NSManagedObjectContext) throws {
        let request = VocabBookEntity.fetchRequest()
        guard try context.count(for: request) == 0 else { return } // 멱등: 책이 하나라도 있으면 스킵

        let book = VocabBookEntity(context: context)
        book.id = UUID()
        book.title = BookTopic.myBook.title
        book.bookType = BookTopic.myBook.rawValue
        book.createAt = Date()

        try context.saveOrRollback()
    }
}
