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
    var originalTopic: String?

    var studyTopic: String? {
        bookType == .myBook ? originalTopic : bookType.rawValue
    }

    /// 나의 단어장 단어는 이미 나의 단어장에 있어 저장 대상이 아니다
    var isSaveable: Bool { bookType != .myBook }
}
