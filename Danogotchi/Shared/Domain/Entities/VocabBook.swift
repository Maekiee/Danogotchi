import Foundation

struct VocabBook: Hashable {
    let id: UUID
    let title: String
    let bookType: BookTopic
    let level: VocabLevel?
    let vocabList: [Vocab]
    let isActive: Bool
    let createAt: Date
}
