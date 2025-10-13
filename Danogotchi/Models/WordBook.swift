import Foundation
import RealmSwift

struct WordBook: Hashable {
    let id: String
    let title: String
    let wordList: [Word]
    let createAt: Date
}

extension WordBook: CardDisplayable {
    var cardThumbnail: String? { nil }
    var cardTitle: String { title }
    var cardSubtitle: String { "\(wordList.count)개 단어" }
    var cardChipText: Int? { nil }
    
    func toObject() -> WordBookObject {
        let wordBook = WordBookObject()
        wordBook.id = try! ObjectId(string: id)
        wordBook.title = title
        wordBook.wordList.append(objectsIn: wordList.map { $0.toObject() })
        wordBook.createAt = createAt
        return wordBook
    }
}


