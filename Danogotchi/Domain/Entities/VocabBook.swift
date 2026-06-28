import Foundation

enum VocabBookType: String {
    case mine
    case recommended
}

struct VocabBook: Hashable {
    let id: UUID
    let title: String
    let type: VocabBookType
    let originBookId: String?   // 추천 단어장 원본 id (내 단어장이면 nil)
    let vocabList: [Vocab]
    let createAt: Date
}
