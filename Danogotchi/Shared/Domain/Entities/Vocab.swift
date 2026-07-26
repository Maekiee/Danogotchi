import Foundation

struct Vocab: Hashable {
    let id: UUID
    let word: String
    let meaning: String
    let bookType: BookTopic
    let level: VocabLevel?
    let partOfSpeech: PartOfSpeech?
    let createAt: Date
}
