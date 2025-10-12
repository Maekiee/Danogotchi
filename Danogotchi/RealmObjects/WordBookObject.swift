import Foundation
import RealmSwift

class WordBookObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var wordList: List<WordObject>
    @Persisted var createAt: Date
    
    convenience init(title: String, createAt: Date) {
        self.init()
        self.title = title
        self.createAt = createAt
    }
}

extension WordBookObject {
    func toStruct() -> WordBook {
        return WordBook(
            id: id.stringValue,
            title: title,
            wordList: wordList.map { $0.toStruct() },
            createAt: createAt
        )
    }
}
