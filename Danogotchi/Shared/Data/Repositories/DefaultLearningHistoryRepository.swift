import Foundation
import CoreData

final class DefaultLearningHistoryRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    private func fetchVocabEntity(id: UUID) throws -> VocabEntity? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
}

extension DefaultLearningHistoryRepository: LearningHistoryRepository {
    func addHistory(vocabId: UUID, isCorrect: Bool) throws {
        guard let vocabEntity = try fetchVocabEntity(id: vocabId) else { throw PersistenceError.entityNotFound }
        
        let history = LearningHistoryEntity(context: context)
        history.id = UUID()
        history.isCorrect = isCorrect
        history.createAt = Date()
        vocabEntity.addToHistories(history)
        
        try context.saveOrRollback()
    }
    
    func fetchAllHistory() throws -> [LearningHistory] {
        let request = LearningHistoryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let entities = try context.fetch(request)
        return entities.map { $0.toDomain() }
    }
    
    func fetchHistory(vocabId: UUID) throws -> [LearningHistory] {
        let request = LearningHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "vocab.id == %@", vocabId as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let entities = try context.fetch(request)
        return entities.map { $0.toDomain() }
    }
    
    func accuracy(vocabId: UUID) throws -> Double? {
        let histories = try fetchHistory(vocabId: vocabId)
        guard !histories.isEmpty else { return nil }
        let correctCount = histories.filter(\.isCorrect).count
        return Double(correctCount) / Double(histories.count)
    }
}
