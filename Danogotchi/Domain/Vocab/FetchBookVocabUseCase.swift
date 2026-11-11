import Foundation

protocol FetchVocabsUseCase {
    /// 활성 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 executeActive()로 다시 읽는다.
    var activeBookChanged: AsyncStream<Void> { get }
    func execute(topic: BookTopic) throws -> [VocabDisplayInfo]
    /// 활성 단어장이 없으면 nil
    func executeActive() throws -> (bookType: BookTopic, items: [VocabDisplayInfo])?
}

final class DefaultFetchVocabsUseCase: FetchVocabsUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let learningHistoryRepository: LearningHistoryRepository

    init(
        vocabBookRepository: VocabBookRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learningHistoryRepository = learningHistoryRepository
    }

    var activeBookChanged: AsyncStream<Void> {
        return vocabBookRepository.activeBookChanged
    }
    
    func execute(topic: BookTopic) throws -> [VocabDisplayInfo] {
        let vocabs = try fetchVocabs(topic: topic)
        return try joinWithHistory(vocabs, savedSourceIDs: savedSourceIDs(topic: topic))
    }

    func executeActive() throws -> (bookType: BookTopic, items: [VocabDisplayInfo])? {
        guard let book = try vocabBookRepository.readActiveBook() else { return nil }
        let items = try joinWithHistory(book.vocabList, savedSourceIDs: savedSourceIDs(topic: book.bookType))
        return (bookType: book.bookType, items: items)
    }

    private func fetchVocabs(topic: BookTopic) throws -> [Vocab] {
        guard let book = try vocabBookRepository.readAllBooks(bookType: topic).first else { return [] }
        if topic == .myBook {
            return try Array(vocabBookRepository.fetchVocabs(inBookId: book.id).reversed())
        }
        return book.vocabList
    }

    /// 추천 단어장 화면에서만 필요 — 나의 단어장에 복사된 단어들의 원본 id 집합
    private func savedSourceIDs(topic: BookTopic) throws -> Set<UUID> {
        guard topic != .myBook,
              let myBook = try vocabBookRepository.readAllBooks(bookType: .myBook).first else { return [] }
        return try Set(vocabBookRepository.fetchVocabs(inBookId: myBook.id).compactMap { $0.sourceWordId })
    }

    // MyBookDetailViewModel의 정답률 집계 로직 이관
    private func joinWithHistory(_ vocabs: [Vocab], savedSourceIDs: Set<UUID>) throws -> [VocabDisplayInfo] {
        let stats = try learningHistoryRepository.fetchAllHistory().statsByVocab()
        return vocabs.map { vocab in
            VocabDisplayInfo(
                word: vocab,
                stats: stats[vocab.id],
                isSaved: savedSourceIDs.contains(vocab.id)
            )
        }
    }
}
