import Foundation
import RealmSwift

protocol WordRepositoryProtocol {
    func create(thumbnail: String, word: String, meaning: String) -> WordObject
    func readAll() -> [WordObject]
    func read(id: ObjectId) -> WordObject?
    func update(id: ObjectId, thumbnail: String?, word: String?, meaning: String?)
    func delete(id: ObjectId)
}
