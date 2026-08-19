import Foundation
import CoreData
import OSLog
import RxSwift
import RxCocoa

final class DefaultVocabBookRepository {
    private let context: NSManagedObjectContext
    /// 변경 신호 전용. 내용은 캐시하지 않고 매번 CoreData에서 다시 읽는다.
    private let activeBookIdRelay = BehaviorRelay<UUID?>(value: nil)

    init(context: NSManagedObjectContext) {
        self.context = context
        activeBookIdRelay.accept(fetchActiveBookEntities().first?.id)
    }

    private func fetchBookEntity(id: UUID) -> VocabBookEntity? {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    /// 불변식상 0~1개지만, 해제 시 잔여물까지 훑도록 fetchLimit을 두지 않는다.
    private func fetchActiveBookEntities() -> [VocabBookEntity] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")

        return (try? context.fetch(request)) ?? []
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            AppLogger.database.error("CoreData 저장 실패: \(String(describing: error), privacy: .public)")
            CrashReporter.record(error)
        }
    }
}

extension DefaultVocabBookRepository: VocabBookRepository {
    var activeBookId: Observable<UUID?> {
        return activeBookIdRelay.asObservable()
    }

    func readActiveBook() -> VocabBook? {
        return fetchActiveBookEntities().first?.toDomain()
    }

    /// 해제와 지정을 한 트랜잭션으로 처리해 "활성 단어장은 항상 1개" 불변식을 저장 시점에 보장한다.
    func setActiveBook(id: UUID) {
        guard let targetEntity = fetchBookEntity(id: id) else { return }

        fetchActiveBookEntities().forEach { $0.isActive = false }
        targetEntity.isActive = true

        saveContext()

        activeBookIdRelay.accept(id)
    }

    func createBook(title: String, bookType: BookTopic, level: VocabLevel?) -> VocabBook {
        let vocabBookEntity = VocabBookEntity(context: context)
        vocabBookEntity.id = UUID()
        vocabBookEntity.title = title
        vocabBookEntity.bookType = bookType.rawValue
        vocabBookEntity.level = level?.rawValue
        vocabBookEntity.createAt = Date()
        
        saveContext()
        
        return vocabBookEntity.toDomain()
    }
    
    func readAllBooks() -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        
        let vocabBookEntities = (try? context.fetch(request)) ?? []
        return vocabBookEntities.map { $0.toDomain() }
    }
    
    func readAllBooks(bookType: BookTopic) -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "bookType == %@", bookType.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let vocabBookEntities = (try? context.fetch(request)) ?? []
        return vocabBookEntities.map { $0.toDomain() }
    }
    
    func readBook(id: UUID) -> VocabBook? {
        return fetchBookEntity(id: id)?.toDomain()
    }
    
    func updateBook(id: UUID, title: String) {
        guard let vocabBookEntity = fetchBookEntity(id: id) else { return }
        vocabBookEntity.title = title
        saveContext()
    }
    
    func deleteBook(id: UUID) {
        guard let vocabBookEntity = fetchBookEntity(id: id) else { return }
        let wasActive = vocabBookEntity.isActive
        context.delete(vocabBookEntity)
        saveContext()

        if wasActive {
            activeBookIdRelay.accept(nil)
        }
    }
    
    /// 사용자가 직접 입력한 값으로 새 단어를 생성해 단어장에 추가
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?, partOfSpeech: PartOfSpeech?) -> Vocab? {
        guard let vocabBookEntity = fetchBookEntity(id: bookId) else { return nil }
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = word
        vocabEntity.meaning = meaning
        vocabEntity.bookType = bookType.rawValue
        vocabEntity.level = level?.rawValue
        vocabEntity.partOfSpeech = partOfSpeech?.rawValue
        vocabEntity.createAt = Date()
        
        vocabBookEntity.addToVocabs(vocabEntity)
        
        saveContext()
        
        return vocabEntity.toDomain()
    }
    
    /// 추천 단어장의 기존 단어를 내 단어장으로 복사해 저장 (sourceWordId로 중복 저장 방지).
    func addVocab(bookId: UUID, from vocab: Vocab) -> Vocab? {
        guard let vocabBookEntity = fetchBookEntity(id: bookId) else { return nil }
        guard findVocab(inBookId: bookId, sourceWordId: vocab.id) == nil else { return nil }

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

        saveContext()

        return vocabEntity.toDomain()
    }

    func fetchVocabs(inBookId id: UUID) -> [Vocab] {
        guard let vocabBookEntity = fetchBookEntity(id: id) else { return [] }
        
        let vocabEntities = (vocabBookEntity.vocabs?.allObjects as? [VocabEntity]) ?? []
        
        return vocabEntities
            .map { $0.toDomain() }
            .sorted { $0.createAt < $1.createAt }
    }

    func findVocab(inBookId id: UUID, sourceWordId: UUID) -> Vocab? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "vocabBook.id == %@ AND sourceWordId == %@",
            id as CVarArg, sourceWordId as CVarArg
        )
        request.fetchLimit = 1

        return (try? context.fetch(request))?.first?.toDomain()
    }
}
