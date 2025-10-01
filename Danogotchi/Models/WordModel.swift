import Foundation
import RealmSwift

struct WordModel: Hashable {
    let id: String
    let thumbnail: String
    let word: String
    let meaning: String
    let createAt: Date
}

extension WordModel {
    func toObject() -> Word {
        let vocab = Word()
        vocab.id = try! ObjectId(string: id)
        vocab.thumbnail = thumbnail
        vocab.word = word
        vocab.meaning = meaning
        vocab.createAt = createAt
        return vocab
    }
}
