import Foundation
import RealmSwift

struct WordBookModel: Hashable {
    let id: String
    let title: String
    let isLearning: Bool
    let wordList: [WordModel]
    let createAt: Date
}

extension WordBookModel {
    func toObject() -> WordBook {
        let wordBook = WordBook()
        wordBook.id = try! ObjectId(string: id)
        wordBook.title = title
        wordBook.isLearning = isLearning
        wordBook.wordList.append(objectsIn: wordList.map { $0.toObject() })
        wordBook.createAt = createAt
        return wordBook
    }
}
