import Foundation
import CoreData
import OSLog

/// 최초 실행 시 토픽별 단어장 + 추천 단어를 CoreData에 시드
enum DatabaseSeeder {
    static func seedIfNeeded(context: NSManagedObjectContext) {
        let request = VocabBookEntity.fetchRequest()
        guard ((try? context.count(for: request)) ?? 0) == 0 else { return } // 멱등: 책이 하나라도 있으면 스킵

        let seeds: [(topic: BookTopic, level: VocabLevel?, words: [(String, String, PartOfSpeech)])] = [
            (.myBook, nil, []),
            (.travel, .a1, MockTravelWords.data),
            (.business, .a1, MockBusinessWords.data),
            (.emotion, .a1, MockEmotionWords.data),
            (.life, .a1, MockLifeWords.data),
        ]

        let base = Date()
        for (bookIndex, seed) in seeds.enumerated() {
            let book = VocabBookEntity(context: context)
            book.id = UUID()
            book.title = seed.topic.title
            book.bookType = seed.topic.rawValue
            book.level = seed.level?.rawValue
            book.createAt = base.addingTimeInterval(Double(bookIndex))

            for (index, word) in seed.words.enumerated() {
                let vocab = VocabEntity(context: context)
                vocab.id = UUID()
                vocab.word = word.0
                vocab.meaning = word.1
                vocab.bookType = seed.topic.rawValue
                vocab.level = seed.level?.rawValue
                vocab.partOfSpeech = word.2.rawValue
                // createAt 정렬을 쓰는 조회가 있어 순서 보존용 시차를 둠
                vocab.createAt = base.addingTimeInterval(Double(index) / 1000)
                book.addToVocabs(vocab)
            }
        }

        do {
            try context.save()
        } catch {
            AppLogger.database.error("DatabaseSeeder 저장 실패: \(String(describing: error), privacy: .public)")
        }
        // ponytail: 첫 실행 ~1.5k행 메인스레드 동기 시드, 데이터가 10배 커지면 background context로
    }
}
