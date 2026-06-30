import Foundation
import CoreData

final class DefaultVocabLearningHistoryRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension DefaultVocabLearningHistoryRepository: VocabLearningHistoryRepository {
    func addHistory(vocabId: UUID, isCorrect: Bool) {
        
    }
    
    func fetchAllHistory() -> [LearningHistory] {
        
    }
    
    func fetchHistory(vocabId: UUID) -> [LearningHistory] {
        
    }
    
    func accuracy(vocabId: UUID) -> Double? {
        
    }
}
