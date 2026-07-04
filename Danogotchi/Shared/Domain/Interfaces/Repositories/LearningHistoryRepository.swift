import Foundation

protocol LearningHistoryRepository {
    func addHistory(vocabId: UUID, isCorrect: Bool)
    func fetchAllHistory() -> [LearningHistory]
    func fetchHistory(vocabId: UUID) -> [LearningHistory]
    func accuracy(vocabId: UUID) -> Double?
}
