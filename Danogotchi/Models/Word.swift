import Foundation
import RealmSwift

struct Word: Hashable {
    let id: String
    let thumbnail: String
    let word: String
    let meaning: String
    let createAt: Date
}

extension Word: CardDisplayable {
    var cardThumbnail: String? { self.thumbnail }
    var cardTitle: String { word }
    var cardSubtitle: String { meaning }
    
    func toObject() -> WordObject {
        let vocab = WordObject()
        vocab.id = try! ObjectId(string: id)
        vocab.thumbnail = thumbnail
        vocab.word = word
        vocab.meaning = meaning
        vocab.createAt = createAt
        return vocab
    }
}
