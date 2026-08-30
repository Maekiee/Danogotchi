import Foundation

struct Vocab: Hashable, Identifiable {
    let id: UUID
    let word: String
    let meaning: String
    let bookType: BookTopic
    let level: VocabLevel?
    let partOfSpeech: PartOfSpeech?
    let sourceWordId: UUID? 
    let createAt: Date
}
