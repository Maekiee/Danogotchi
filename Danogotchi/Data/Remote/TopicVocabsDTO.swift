import Foundation

/// Firestore `topicVocabs/{topic}_{level}` 문서
struct TopicVocabsDTO: Decodable {
    struct Word: Decodable {
        let id: String
        let word: String
        let pos: String?
        let meaning: [String: String]
    }

    let words: [Word]

    /// 뜻은 앱 언어가 ja면 일본어, 그 외 한국어. id가 UUID가 아니거나 뜻이 없는 단어는 건너뛴다
    func toDomain(key: VocabBookKey, language: String?, base: Date) -> [Vocab] {
        let meaningKey = language == "ja" ? "ja" : "ko"
        return words.enumerated().compactMap { index, word in
            guard let id = UUID(uuidString: word.id), let meaning = word.meaning[meaningKey] else { return nil }
            return Vocab(
                id: id,
                word: word.word,
                meaning: meaning,
                bookType: key.topic,
                level: key.level,
                partOfSpeech: word.pos.flatMap(PartOfSpeech.init(rawValue:)),
                sourceWordId: nil,
                // createAt 정렬을 쓰는 조회가 있어 순서 보존용 시차를 둠
                createAt: base.addingTimeInterval(Double(index) / 1000)
            )
        }
    }
}
