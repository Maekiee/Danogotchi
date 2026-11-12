import Foundation

protocol IsActiveBookUseCase {
    /// 단어장이 학습중인지 여부. 받지 않은 단어장이면 false.
    func execute(key: VocabBookKey) throws -> Bool
}

final class DefaultIsActiveBookUseCase: IsActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(key: VocabBookKey) throws -> Bool {
        return try vocabBookRepository.readBookSummary(key: key)?.isActive ?? false
    }
}
