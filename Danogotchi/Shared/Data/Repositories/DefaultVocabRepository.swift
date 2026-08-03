import Foundation
import CoreData

final class DefaultVocabRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // CoreData에 저장된 값을 가져오기 위한 헬퍼 함수
    private func fetchEntity(id: UUID) -> VocabEntity? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // CoreData에 저장하기 위한 헬퍼 함수
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData 저장 실패: \(error)")
        }
    }
}

extension DefaultVocabRepository: VocabRepository {
    func createVocab(vocab: String, meaning: String) -> Vocab {
        let vocabEntity = VocabEntity(context: context)
        vocabEntity.id = UUID()
        vocabEntity.word = vocab
        vocabEntity.meaning = meaning
        vocabEntity.bookType = BookTopic.myBook.rawValue
        vocabEntity.createAt = Date()
        
        
        saveContext()
        
        return vocabEntity.toDomain()
    }
    
    func readAllVocab() -> [Vocab] {
        let request = VocabEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        
        let vocabEntities = (try? context.fetch(request)) ?? []
        return vocabEntities.map { $0.toDomain() }
    }
    
    func readVocab(id: UUID) -> Vocab? {
        return fetchEntity(id: id)?.toDomain()
    }
    
    func updateVocab(id: UUID, word: String?, meaning: String?, partOfSpeech: PartOfSpeech?) {
        guard let vocabEntity = fetchEntity(id: id) else { return }
        
        if let word = word {
            vocabEntity.word = word
        }
        
        if let meaning = meaning {
            vocabEntity.meaning = meaning
        }
        
        if let partOfSpeech = partOfSpeech {
            vocabEntity.partOfSpeech = partOfSpeech.rawValue
        }
        
        saveContext()
    }
    
    func deleteVocab(id: UUID) {
        guard let vocabEntity = fetchEntity(id: id) else { return }
        
        context.delete(vocabEntity)
        saveContext()
    }
}
