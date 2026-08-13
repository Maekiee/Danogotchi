import Foundation
import CoreData
import OSLog

final class DefaultLearningHistoryRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    private func fetchVocabEntity(id: UUID) -> VocabEntity? {
        let request = VocabEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            AppLogger.database.error("CoreData 저장 실패: \(String(describing: error), privacy: .public)")
        }
    }
}

extension DefaultLearningHistoryRepository: LearningHistoryRepository {
    func addHistory(vocabId: UUID, isCorrect: Bool) {
        guard let vocabEntity = fetchVocabEntity(id: vocabId) else { return }
        
        let history = LearningHistoryEntity(context: context)
        history.id = UUID()
        history.isCorrect = isCorrect
        history.createAt = Date()
        vocabEntity.addToHistories(history)
        
        saveContext()
    }
    
    func fetchAllHistory() -> [LearningHistory] {
        let request = LearningHistoryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { $0.toDomain() }
    }
    
    func fetchHistory(vocabId: UUID) -> [LearningHistory] {
        let request = LearningHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "vocab.id == %@", vocabId as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { $0.toDomain() }
    }
    
    func accuracy(vocabId: UUID) -> Double? {
        let histories = fetchHistory(vocabId: vocabId)
        guard !histories.isEmpty else { return nil }
        let correctCount = histories.filter(\.isCorrect).count
        return Double(correctCount) / Double(histories.count)
    }
}
