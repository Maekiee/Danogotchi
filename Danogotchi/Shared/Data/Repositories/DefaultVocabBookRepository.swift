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
    func createBook(title: String, type: VocabBookType, originBookId: String?) -> VocabBook {
        let vocabBookEntity = VocabBookEntity(context: context)
        vocabBookEntity.id = UUID()
        vocabBookEntity.title = title
        vocabBookEntity.type = type.rawValue
        vocabBookEntity.originBookId = originBookId
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
    
    func readAllBooks(type: VocabBookType) -> [VocabBook] {
        let request = VocabBookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type.rawValue)
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
    
    func addVocab(bookId: UUID, word: String, meaning: String, originWordId: String?) -> Vocab? {
        guard let vocabBookEntity = fetchBookEntity(id: bookId) else { return nil }
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = word
        vocabEntity.meaning = meaning
        vocabEntity.originWordId = originWordId
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
}
