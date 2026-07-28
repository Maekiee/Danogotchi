import Foundation

struct Vocab: Hashable, Identifiable {
    let id: UUID
    let word: String
    let meaning: String
    let bookType: BookTopic
    let level: VocabLevel?
    let partOfSpeech: PartOfSpeech?
    let sourceWordId: UUID? /// 추천 단어를 복사해 저장한 단어면 원본 id. 직접 추가한 단어는 nil.
    let createAt: Date
}
