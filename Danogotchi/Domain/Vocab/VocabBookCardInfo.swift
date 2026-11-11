import Foundation

struct VocabBookCardInfo: Hashable {
    let id: UUID
    let topic: BookTopic
    let isActive: Bool
}
