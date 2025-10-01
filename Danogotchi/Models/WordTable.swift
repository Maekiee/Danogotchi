import Foundation
import RealmSwift

class WordBook: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var wordList: List<Word>
    @Persisted var isLearning: Bool
    @Persisted var createAt: Date
    
    convenience init(title: String, isLearning: Bool, createAt: Date) {
        self.init()
        self.title = title
        self.isLearning = isLearning
        self.createAt = createAt
    }
}

extension WordBook {
    func toStruct() -> WordBookModel {
        return WordBookModel(
            id: id.stringValue,
            title: title,
            isLearning: isLearning,
            wordList: wordList.map { $0.toStruct() },
            createAt: createAt
        )
    }
}

class Word: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(originProperty: "wordList") var wordBook: LinkingObjects<WordBook>
    
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

extension Word {
    func toStruct() -> WordModel {
        return WordModel(
            id: id.stringValue,
            thumbnail: thumbnail,
            word: word,
            meaning: meaning,
            createAt: createAt
        )
    }
}
