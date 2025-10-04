import Foundation
import RealmSwift

protocol WordBookRepositoryProtocol {
    func create(title: String)
    func readAll() -> [WordBookModel]
    func read(id: ObjectId) -> WordBook?
    func fetchWordsInWordBook(id: ObjectId) -> [WordModel]
    func update(id: ObjectId, title: String)
    func delete(id: ObjectId)
    func addWord(bookId: ObjectId, word: Word)
}
