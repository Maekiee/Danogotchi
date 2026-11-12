import Foundation

protocol SetActiveBookUseCase {
    /// 단어장의 학습중 여부를 바꾼다. 받지 않은 단어장을 켜면 화면이 받아 둔 loaded를, 비었으면 서버에서 받은 단어를 저장한다
    @MainActor func execute(key: VocabBookKey, isActive: Bool, loaded: [Vocab]) async throws
}

final class DefaultSetActiveBookUseCase: SetActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let remoteVocabBookRepository: RemoteVocabBookRepository

    init(
        vocabBookRepository: VocabBookRepository,
        remoteVocabBookRepository: RemoteVocabBookRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.remoteVocabBookRepository = remoteVocabBookRepository
    }

    @MainActor
    func execute(key: VocabBookKey, isActive: Bool, loaded: [Vocab]) async throws {
        if let book = try vocabBookRepository.readBookSummary(key: key) {
            try vocabBookRepository.setActive(id: book.id, isActive: isActive)
            return
        }
        // 받지 않은 단어장은 끌 것이 없다
        guard isActive else { return }

        var vocabs = loaded
        if vocabs.isEmpty {
            vocabs = try await remoteVocabBookRepository.fetchVocabs(key: key)
            // 받는 사이 다른 화면이 같은 단어장을 저장했으면 중복 저장하지 않는다
            if let book = try vocabBookRepository.readBookSummary(key: key) {
                try vocabBookRepository.setActive(id: book.id, isActive: true)
                return
            }
        }
        // 빈 단어장을 저장하면 받은 것으로 보여 다시 받을 수 없다
        guard !vocabs.isEmpty else { throw VocabBookDownloadError.emptyBook }
        _ = try vocabBookRepository.importBook(key: key, vocabs: vocabs, isActive: true)
    }
}
