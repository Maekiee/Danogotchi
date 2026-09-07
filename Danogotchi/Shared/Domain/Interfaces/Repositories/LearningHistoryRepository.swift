import Foundation

protocol LearningHistoryRepository {
    func addHistory(vocabId: UUID, isCorrect: Bool) throws
    func fetchAllHistory() throws -> [LearningHistory]
    func fetchHistory(vocabId: UUID) throws -> [LearningHistory]
    func accuracy(vocabId: UUID) throws -> Double?
}
