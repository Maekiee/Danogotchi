import Foundation
import RealmSwift

protocol WordRepositoryProtocol {
    func create(thumbnail: String, word: String, meaning: String) -> Word
    func readAll() -> [Word]
    func read(id: ObjectId) -> Word?
    func update(id: ObjectId, thumbnail: String?, word: String?, meaning: String?)
    func delete(id: ObjectId)
}
