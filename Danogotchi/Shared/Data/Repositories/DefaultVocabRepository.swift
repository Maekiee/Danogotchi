import Foundation
import CoreData

final class DefaultVocabRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // CoreData에 저장된 값을 가져오기 위한 헬퍼 함수
    private func fetchEntity(id: UUID) throws -> VocabEntity? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
}

extension DefaultVocabRepository: VocabRepository {
    func createVocab(vocab: String, meaning: String) throws -> Vocab {
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = vocab
        vocabEntity.meaning = meaning
        vocabEntity.bookType = BookTopic.myBook.rawValue
        vocabEntity.createAt = Date()
        
        
        try context.saveOrRollback()
        
        return vocabEntity.toDomain()
    }
    
    func readAllVocab() throws -> [Vocab] {
        let request = VocabEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        
        let vocabEntities = try context.fetch(request)
        return vocabEntities.map { $0.toDomain() }
    }
    
    func readVocab(id: UUID) throws -> Vocab? {
        return try fetchEntity(id: id)?.toDomain()
    }
    
    func updateVocab(id: UUID, word: String?, meaning: String?, partOfSpeech: PartOfSpeech?) throws {
        guard let vocabEntity = try fetchEntity(id: id) else { throw PersistenceError.entityNotFound }
        
        if let word = word {
            vocabEntity.word = word
        }
        
        if let meaning = meaning {
            vocabEntity.meaning = meaning
        }
        
        if let partOfSpeech = partOfSpeech {
            vocabEntity.partOfSpeech = partOfSpeech.rawValue
        }
        
        try context.saveOrRollback()
    }
    
    func deleteVocab(id: UUID) throws {
        guard let vocabEntity = try fetchEntity(id: id) else { throw PersistenceError.entityNotFound }
        
        context.delete(vocabEntity)
        try context.saveOrRollback()
    }
}
