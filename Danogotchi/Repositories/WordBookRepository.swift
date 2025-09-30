import Foundation
import RealmSwift

final class WordBookRepository: WordBookRepositoryProtocol {
    private let realm: Realm
    
    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }
    
    // 단어장 생성
    func create(title: String) {
        let wordBook = WordBook(title: title)
        try? realm.write {
            realm.add(wordBook)
        }
    }
    
    func readAll() -> [WordBook] {
        return Array(realm.objects(WordBook.self))
    }
    
    func read(id: ObjectId) -> WordBook? {
        return realm.object(ofType: WordBook.self, forPrimaryKey: id)
    }
    
    func update(id: ObjectId, title: String) {
        guard let wordBook = read(id: id) else { return }
        try? realm.write {
            wordBook.title = title
        }
    }
    
    func delete(id: ObjectId) {
        guard let wordBook = read(id: id) else { return }
        try? realm.write {
            realm.delete(wordBook.wordList) // 연결된 단어들도 삭제 해야됨
            realm.delete(wordBook)
        }
    }
    
    func addWord(bookId: ObjectId, word: Word) {
        guard let wordBook = read(id: bookId) else { return }
        try? realm.write {
            wordBook.wordList.insert(word, at: 0)
        }
    }
    
    
}
