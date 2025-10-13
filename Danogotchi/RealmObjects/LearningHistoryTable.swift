import Foundation
import RealmSwift

class LearningHistoryObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var wordObjectId: ObjectId
    @Persisted var isCorrect: Bool
    @Persisted var createAt: Date
    
    convenience init(
        wordObjectId: ObjectId,
        isCorrect: Bool,
        learningDate: Date = Date()
    ) {
        self.init()
        self.wordObjectId = wordObjectId
        self.isCorrect = isCorrect
        self.createAt = createAt
    }
}

extension LearningHistoryObject {
    func toStruct() -> LearningHistoryModel {
        return LearningHistoryModel(
            wordId: wordObjectId.stringValue,
            isCorrect: isCorrect
        )
    }
}



