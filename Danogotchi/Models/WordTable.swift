import Foundation
import RealmSwift


class WordBook: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var wordList: List<Word>
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
}

class Word: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(originProperty: "wordList") var wordBook: LinkingObjects<WordBook>
    
    @Persisted var thumbnail: String
    @Persisted var word: String
    @Persisted var meaning: String
    
    convenience init(thumbnail: String, word: String, meaning:String) {
        self.init()
        self.thumbnail = thumbnail
        self.word = word
        self.meaning = meaning
    }
}
