import Foundation
import RealmSwift

struct CreateWord {
    let wordBookId: ObjectId?
    let wordId: ObjectId?
    let bookTitle: String
    let word: String
    let meaning: String
    let actionType: EntryPoint
}
