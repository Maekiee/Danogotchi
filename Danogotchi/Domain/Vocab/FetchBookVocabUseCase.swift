import Foundation

protocol FetchVocabsUseCase {
    /// 학습중 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 executeActive()로 다시 읽는다.
    var activeBookChanged: AsyncStream<Void> { get }
    /// 받은 단어장은 CoreData에서, 받지 않은 단어장은 화면이 받아 둔 loaded에서, 그것도 비었으면 서버 문서 1개에서 읽는다
    @MainActor func execute(key: VocabBookKey, loaded: [Vocab]) async throws -> [VocabDisplayInfo]
    /// 학습중 단어장 단어의 합. 학습중 단어장이 없으면 빈 배열
    func executeActive() throws -> [VocabDisplayInfo]
}

final class DefaultFetchVocabsUseCase: FetchVocabsUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let remoteVocabBookRepository: RemoteVocabBookRepository
    private let learningHistoryRepository: LearningHistoryRepository

    init(
        vocabBookRepository: VocabBookRepository,
        remoteVocabBookRepository: RemoteVocabBookRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.remoteVocabBookRepository = remoteVocabBookRepository
        self.learningHistoryRepository = learningHistoryRepository
    }

    var activeBookChanged: AsyncStream<Void> {
        return vocabBookRepository.activeBookChanged
    }
    
    @MainActor
    func execute(key: VocabBookKey, loaded: [Vocab]) async throws -> [VocabDisplayInfo] {
        let vocabs: [Vocab]
        if let book = try vocabBookRepository.readBookSummary(key: key) {
            let local = try vocabBookRepository.fetchVocabs(inBookId: book.id)
            vocabs = key.topic == .myBook ? local.reversed() : local
        } else if !loaded.isEmpty {
            // 다시 읽지 않고 정답률·저장 여부만 새로 붙인다
            vocabs = loaded
        } else {
            vocabs = try await remoteVocabBookRepository.fetchVocabs(key: key)
        }
        return try joinWithHistory(vocabs, savedSourceIDs: savedSourceIDs())
    }

    func executeActive() throws -> [VocabDisplayInfo] {
        return try joinWithHistory(vocabBookRepository.readActiveBooks().learningVocabs, savedSourceIDs: savedSourceIDs())
    }

    /// 나의 단어장에 복사된 단어들의 원본 id 집합
    private func savedSourceIDs() throws -> Set<UUID> {
        guard let myBook = try vocabBookRepository.readBookSummary(key: VocabBookKey(topic: .myBook, level: nil)) else { return [] }
        return try Set(vocabBookRepository.fetchVocabs(inBookId: myBook.id).compactMap { $0.sourceWordId })
    }

    // MyBookDetailViewModel의 정답률 집계 로직 이관
    private func joinWithHistory(_ vocabs: [Vocab], savedSourceIDs: Set<UUID>) throws -> [VocabDisplayInfo] {
        let stats = try learningHistoryRepository.fetchAllHistory().statsByVocab()
        return vocabs.map { vocab in
            VocabDisplayInfo(
                word: vocab,
                stats: stats[vocab.id],
                // 저장 여부는 추천 단어에만 있다
                isSaved: vocab.bookType != .myBook && savedSourceIDs.contains(vocab.id)
            )
        }
    }
}
