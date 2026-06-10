import Foundation
import RealmSwift

protocol LearningHistoryRepository {
    func addHistory(wordObjectId: ObjectId, isCorrect: Bool)
    func fetchAllHistory() -> [LearningHistoryModel]
}
