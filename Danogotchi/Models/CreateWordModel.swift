import Foundation
import RealmSwift

struct CreateWordModel {
    let wordBookId: ObjectId?
    let wordId: ObjectId?
    let thumbnail: String
    let bookTitle: String
    let word: String
    let meaning: String
    let actionType: EntryPoint
}
