import Foundation
import CoreData

final class DefaultVocabBookRepository {
    private let context: NSManagedObjectContext
    /// 변경 신호 전용. 내용은 캐시하지 않고 매번 CoreData에서 다시 읽는다.
    private let activeBookChangedBroadcaster = AsyncBroadcaster<Void>()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    private func fetchBookEntity(id: UUID) throws -> VocabBookEntity? {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

}

extension DefaultVocabBookRepository: VocabBookRepository {
    var activeBookChanged: AsyncStream<Void> {
        return activeBookChangedBroadcaster.stream()
    }

    func readActiveBooks() throws -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]

        return try context.fetch(request).map { $0.toDomain() }
    }

    func setActive(id: UUID, isActive: Bool) throws {
        guard let vocabBookEntity = try fetchBookEntity(id: id) else { throw PersistenceError.entityNotFound }
        vocabBookEntity.isActive = isActive

        try context.saveOrRollback()

        activeBookChangedBroadcaster.send(())
    }

    func importBook(key: VocabBookKey, vocabs: [Vocab], isActive: Bool) throws -> VocabBook {
        let vocabBookEntity = VocabBookEntity(context: context)
        vocabBookEntity.id = UUID()
        // 기존 시드·설치본과 같은 주제 제목 — 레벨이 붙은 표시용 제목은 화면이 만든다
        vocabBookEntity.title = key.topic.title
        vocabBookEntity.bookType = key.topic.rawValue
        vocabBookEntity.level = key.level?.rawValue
        vocabBookEntity.isActive = isActive
        vocabBookEntity.createAt = Date()

        for vocab in vocabs {
            let vocabEntity = VocabEntity(context: context)
            vocabEntity.id = vocab.id
            vocabEntity.word = vocab.word
            vocabEntity.meaning = vocab.meaning
            vocabEntity.bookType = vocab.bookType.rawValue
            vocabEntity.level = vocab.level?.rawValue
            vocabEntity.partOfSpeech = vocab.partOfSpeech?.rawValue
            vocabEntity.createAt = vocab.createAt
            vocabBookEntity.addToVocabs(vocabEntity)
        }

        try context.saveOrRollback()

        if isActive {
            activeBookChangedBroadcaster.send(())
        }
        return vocabBookEntity.toDomain()
    }

    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) throws -> VocabBook {
        let vocabBookEntity = VocabBookEntity(context: context)
        vocabBookEntity.id = UUID()
        vocabBookEntity.title = title
        vocabBookEntity.bookType = bookType.rawValue
        vocabBookEntity.level = level?.rawValue
        vocabBookEntity.createAt = Date()
        
        try context.saveOrRollback()
        
        return vocabBookEntity.toDomain()
    }
    
    func readBookSummaries() throws -> [VocabBookSummary] {
        let request = VocabBookEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        return try context.fetch(request).map { $0.toSummary() }
    }

    func readAllBooks() throws -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        
        let vocabBookEntities = try context.fetch(request)
        return vocabBookEntities.map { $0.toDomain() }
    }
    
    func readAllBooks(bookType: BookTopic) throws -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "bookType == %@", bookType.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let vocabBookEntities = try context.fetch(request)
        return vocabBookEntities.map { $0.toDomain() }
    }
    
    func readBook(id: UUID) throws -> VocabBook? {
        return try fetchBookEntity(id: id)?.toDomain()
    }
    
    func updateBook(id: UUID, title: String) throws {
        guard let vocabBookEntity = try fetchBookEntity(id: id) else { throw PersistenceError.entityNotFound }
        vocabBookEntity.title = title
        try context.saveOrRollback()
    }
    
    func deleteBook(id: UUID) throws {
        guard let vocabBookEntity = try fetchBookEntity(id: id) else { throw PersistenceError.entityNotFound }
        let wasActive = vocabBookEntity.isActive
        context.delete(vocabBookEntity)
        try context.saveOrRollback()

        if wasActive {
            activeBookChangedBroadcaster.send(())
        }
    }
    
    /// 사용자가 직접 입력한 값으로 새 단어를 생성해 단어장에 추가
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?, partOfSpeech: PartOfSpeech?) throws -> Vocab {
        guard let vocabBookEntity = try fetchBookEntity(id: bookId) else { throw PersistenceError.entityNotFound }
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = word
        vocabEntity.meaning = meaning
        vocabEntity.bookType = bookType.rawValue
        vocabEntity.level = level?.rawValue
        vocabEntity.partOfSpeech = partOfSpeech?.rawValue
        vocabEntity.createAt = Date()
        
        vocabBookEntity.addToVocabs(vocabEntity)
        
        try context.saveOrRollback()
        
        return vocabEntity.toDomain()
    }
    
    /// 추천 단어장의 기존 단어를 내 단어장으로 복사해 저장.
    /// sourceWordId로 중복을 막되, 이미 담긴 단어는 정상 상태이므로 실패가 아니라 기존 단어를 돌려준다.
    func addVocab(bookId: UUID, from vocab: Vocab) throws -> Vocab {
        guard let vocabBookEntity = try fetchBookEntity(id: bookId) else { throw PersistenceError.entityNotFound }
        if let saved = try findVocab(inBookId: bookId, sourceWordId: vocab.id) { return saved }

        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = vocab.word
        vocabEntity.meaning = vocab.meaning
        vocabEntity.bookType = BookTopic.myBook.rawValue
        vocabEntity.level = vocab.level?.rawValue
        vocabEntity.partOfSpeech = vocab.partOfSpeech?.rawValue
        vocabEntity.sourceWordId = vocab.id
        vocabEntity.originalTopic = vocab.studyTopic
        vocabEntity.createAt = Date()

        vocabBookEntity.addToVocabs(vocabEntity)

        try context.saveOrRollback()

        return vocabEntity.toDomain()
    }

    func fetchVocabs(inBookId id: UUID) throws -> [Vocab] {
        guard let vocabBookEntity = try fetchBookEntity(id: id) else { return [] }
        
        let vocabEntities = (vocabBookEntity.vocabs?.allObjects as? [VocabEntity]) ?? []
        
        return vocabEntities
            .map { $0.toDomain() }
            .sorted { $0.createAt < $1.createAt }
    }

    func findVocab(inBookId id: UUID, sourceWordId: UUID) throws -> Vocab? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "vocabBook.id == %@ AND sourceWordId == %@",
            id as CVarArg, sourceWordId as CVarArg
        )
        request.fetchLimit = 1

        return try context.fetch(request).first?.toDomain()
    }
}
