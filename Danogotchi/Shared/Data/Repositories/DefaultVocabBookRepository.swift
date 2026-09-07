import Foundation
import CoreData
import RxSwift
import RxCocoa

final class DefaultVocabBookRepository {
    private let context: NSManagedObjectContext
    /// 변경 신호 전용. 내용은 캐시하지 않고 매번 CoreData에서 다시 읽는다.
    private let activeBookChangedRelay = PublishRelay<Void>()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    private func fetchBookEntity(id: UUID) throws -> VocabBookEntity? {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    /// 불변식상 0~1개지만, 해제 시 잔여물까지 훑도록 fetchLimit을 두지 않는다.
    private func fetchActiveBookEntities() throws -> [VocabBookEntity] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")

        return try context.fetch(request)
    }

}

extension DefaultVocabBookRepository: VocabBookRepository {
    var activeBookChanged: Observable<Void> {
        return activeBookChangedRelay.asObservable()
    }

    func readActiveBook() throws -> VocabBook? {
        return try fetchActiveBookEntities().first?.toDomain()
    }

    /// 해제와 지정을 한 트랜잭션으로 처리해 "활성 단어장은 항상 1개" 불변식을 저장 시점에 보장한다.
    func setActiveBook(id: UUID) throws {
        guard let targetEntity = try fetchBookEntity(id: id) else { throw PersistenceError.entityNotFound }

        try fetchActiveBookEntities().forEach { $0.isActive = false }
        targetEntity.isActive = true

        try context.saveOrRollback()

        activeBookChangedRelay.accept(())
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
            activeBookChangedRelay.accept(())
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
