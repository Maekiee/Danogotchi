import Foundation

struct VocabBook: Hashable {
    let id: UUID
    let title: String
    let bookType: BookTopic
    let level: VocabLevel?
    let vocabList: [Vocab]
    let isActive: Bool
    let createAt: Date

    var key: VocabBookKey { VocabBookKey(topic: bookType, level: level) }
}

extension Array where Element == VocabBook {
    /// 학습중 단어장 단어의 합. 같은 단어가 두 번 나오지 않게 원본이 함께 있는 나의 단어장 복사본은 뺀다
    var learningVocabs: [Vocab] {
        let vocabs = filter(\.isActive).flatMap(\.vocabList)
        let ids = Set(vocabs.map(\.id))
        // 서버 데이터에 id가 겹쳐도 화면이 깨지지 않게 한 번만 남긴다
        var seen = Set<UUID>()
        return vocabs.filter { vocab in
            (vocab.sourceWordId.map { !ids.contains($0) } ?? true) && seen.insert(vocab.id).inserted
        }
    }
}
