import Foundation

protocol LearningHistoryRepository {
    func addHistory(_ answer: QuizAnswer) throws
    func fetchAllHistory() throws -> [LearningHistory]
    func fetchHistory(vocabId: UUID) throws -> [LearningHistory]
    func accuracy(vocabId: UUID) throws -> Double?
    func fetchReportRecords() async throws -> StudyReportRecords
}
