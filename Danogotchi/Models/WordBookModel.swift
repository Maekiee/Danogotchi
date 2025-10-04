import Foundation
import RealmSwift

struct WordBookModel: Hashable {
    let id: String
    let title: String
    let wordList: [WordModel]
    let createAt: Date
}

extension WordBookModel: CardDisplayable {
    var cardThumbnail: String? { nil }
    var cardTitle: String { title }
    var cardSubtitle: String { "\(wordList.count)개 단어" }
    
    func toObject() -> WordBook {
        let wordBook = WordBook()
        wordBook.id = try! ObjectId(string: id)
        wordBook.title = title
        wordBook.wordList.append(objectsIn: wordList.map { $0.toObject() })
        wordBook.createAt = createAt
        return wordBook
    }
}


