import Foundation
import RealmSwift

final class WordRepository: WordRepositoryProtocol {
    private let realm: Realm
    
    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }
    
    func create(thumbnail: String, word: String, meaning: String) -> Word {
        let word = Word(thumbnail: thumbnail, word: word, meaning: meaning, createAt: Date())
        try? realm.write {
            realm.add(word)
        }
        return word
    }
    
    // 단어 스크마에 있는 전체 단어를 불러옴
    func readAll() -> [Word] {
        return Array(realm.objects(Word.self))
    }
    
    // 특정 레코드의 id값으로 특정 단어만 가져옴
    func read(id: ObjectId) -> Word? {
        return realm.object(ofType: Word.self, forPrimaryKey: id)
    }
    
    func update(id: RealmSwift.ObjectId, thumbnail: String?, word: String?, meaning: String?) {
        guard let targetWord = read(id: id) else { return }
        try? realm.write {
            if let thumbnail = thumbnail {
                targetWord.thumbnail = thumbnail
            }
            if let word = word {
                targetWord.word = word
            }
            if let meaning = meaning {
                targetWord.meaning = meaning
            }
        }
    }
    
    func delete(id: RealmSwift.ObjectId) {
        guard let word = read(id: id) else { return }
        try? realm.write {
            realm.delete(word)
        }
    }
    
    
}
