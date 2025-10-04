import Foundation
import RealmSwift

final class WordBookRepository: WordBookRepositoryProtocol {
    private let realm: Realm
    
    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }
    
    // 새로운 단어장 생성
    func create(title: String) {
        let wordBook = WordBook(title: title, createAt: Date())
        try? realm.write {
            realm.add(wordBook)
        }
    }
    
    // 단어장 세트 불러오기
    func readAll() -> [WordBookModel] {
        let wordBooks = Array(realm.objects(WordBook.self))
        return wordBooks.map { $0.toStruct() }
//        return Array(realm.objects(WordBook.self))
    }
    
    func read(id: ObjectId) -> WordBook? {
        return realm.object(ofType: WordBook.self, forPrimaryKey: id)
    }
    
    // 특정 단어장의 단어들 가져오기
    func fetchWordsInWordBook(id: ObjectId) -> [WordModel] {
        guard let wordBook = read(id: id) else { return [] }
        return wordBook.wordList.map { $0.toStruct() }
    }
    
    // 단어장 수정: 타이틀, 학습 상태
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
            wordBook.wordList.append(word)
        }
    }
}
