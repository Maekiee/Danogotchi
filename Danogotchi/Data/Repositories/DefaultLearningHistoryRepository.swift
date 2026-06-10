import Foundation
import RealmSwift

final class DefaultLearningHistoryRepository: LearningHistoryRepository{
    private let realm: Realm
    
    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }
    
    func addHistory(wordObjectId: ObjectId, isCorrect: Bool) {
            let history = LearningHistoryObject(
                wordObjectId: wordObjectId,
                isCorrect: isCorrect,
                learningDate: Date()
            )
            
            try? realm.write {
                realm.add(history)
            }
        }
    
    func fetchAllHistory() -> [LearningHistoryModel] {
        let learningHistories = Array(realm.objects(LearningHistoryObject.self))
        return learningHistories.map { $0.toStruct() }
    }
}
