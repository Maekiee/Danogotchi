import Foundation
import RealmSwift

class WordObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(originProperty: "wordList") var wordBook: LinkingObjects<WordBookObject>
    
    @Persisted var thumbnail: String
    @Persisted var word: String
    @Persisted var meaning: String
    @Persisted var createAt: Date
    
    convenience init(thumbnail: String, word: String, meaning:String, createAt: Date) {
        self.init()
        self.thumbnail = thumbnail
        self.word = word
        self.meaning = meaning
        self.createAt = createAt
    }
}

extension WordObject {
    func toStruct() -> Word {
        return Word(
            id: id.stringValue,
            thumbnail: thumbnail,
            word: word,
            meaning: meaning,
            createAt: createAt
        )
    }
}
