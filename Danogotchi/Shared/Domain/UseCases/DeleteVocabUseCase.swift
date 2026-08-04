import Foundation

protocol DeleteVocabUseCase {
    func execute(vocab: Vocab)
}

final class DefaultDeleteVocabUseCase: DeleteVocabUseCase {
    private let vocabRepository: VocabRepository

    init(vocabRepository: VocabRepository) {
        self.vocabRepository = vocabRepository
    }

    func execute(vocab: Vocab) {
        vocabRepository.deleteVocab(id: vocab.id)
    }
}
