import Foundation

protocol SelectInterestUseCase {
    /// 온보딩 관심 주제 선택. 그 주제의 A1을 받아 학습중으로 두고, 다른 단어장의 학습중은 해제한다
    @MainActor func execute(topic: BookTopic) async throws
}

final class DefaultSelectInterestUseCase: SelectInterestUseCase {
    private let setActiveBookUseCase: SetActiveBookUseCase
    private let vocabBookRepository: VocabBookRepository

    init(setActiveBookUseCase: SetActiveBookUseCase, vocabBookRepository: VocabBookRepository) {
        self.setActiveBookUseCase = setActiveBookUseCase
        self.vocabBookRepository = vocabBookRepository
    }

    @MainActor
    func execute(topic: BookTopic) async throws {
        let key = VocabBookKey(topic: topic, level: .a1)
        try await setActiveBookUseCase.execute(key: key, isActive: true, loaded: [])
        // 온보딩을 다시 하면 마지막에 고른 주제만 남긴다 — 해제한 단어장의 단어는 남는다
        for book in try vocabBookRepository.readBookSummaries() where book.isActive && book.key != key {
            try vocabBookRepository.setActive(id: book.id, isActive: false)
        }
    }
}
