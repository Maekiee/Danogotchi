import Foundation
import RealmSwift

protocol LearningHistoryRepositoryProtocol {
    func addHistory(wordObjectId: ObjectId, isCorrect: Bool)
    func fetchAllHistory() -> [LearningHistoryModel]
}
