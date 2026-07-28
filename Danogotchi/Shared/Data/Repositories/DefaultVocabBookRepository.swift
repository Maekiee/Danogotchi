import Foundation
import CoreData

final class DefaultVocabBookRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    private func fetchBookEntity(id: UUID) -> VocabBookEntity? {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData 저장 실패: \(error)")
        }
    }
}

extension DefaultVocabBookRepository: VocabBookRepository {
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
        context.delete(vocabBookEntity)
        saveContext()
    }
    
    /// 사용자가 직접 입력한 값으로 새 단어를 생성해 단어장에 추가
    func addVocab(bookId: UUID, word: String, meaning: String, bookType: BookTopic, level: VocabLevel?) -> Vocab? {
        guard let vocabBookEntity = fetchBookEntity(id: bookId) else { return nil }
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = word
        vocabEntity.meaning = meaning
        vocabEntity.bookType = bookType.rawValue
        vocabEntity.level = level?.rawValue
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
