import Foundation

struct CreateVocab {
    let vocabBookId: UUID?
    let vocabId: UUID?
    let bookTitle: String
    let word: String
    let meaning: String
    let actionType: EntryPoint
}
