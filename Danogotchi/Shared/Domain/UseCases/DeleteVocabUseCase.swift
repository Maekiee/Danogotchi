import Foundation

protocol DeleteVocabUseCase {
    func execute(vocab: Vocab) throws
}

final class DefaultDeleteVocabUseCase: DeleteVocabUseCase {
    private let vocabRepository: VocabRepository

    init(vocabRepository: VocabRepository) {
        self.vocabRepository = vocabRepository
    }

    func execute(vocab: Vocab) throws {
        try vocabRepository.deleteVocab(id: vocab.id)
    }
}
