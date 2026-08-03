import Foundation

protocol UpdateVocabUseCase {
    /// 사용자가 직접 추가한 단어의 내용을 수정한다.
    func execute(id: UUID, word: String, meaning: String, partOfSpeech: PartOfSpeech)
}

final class DefaultUpdateVocabUseCase: UpdateVocabUseCase {
    private let vocabRepository: VocabRepository

    init(vocabRepository: VocabRepository) {
        self.vocabRepository = vocabRepository
    }

    func execute(id: UUID, word: String, meaning: String, partOfSpeech: PartOfSpeech) {
        vocabRepository.updateVocab(
            id: id,
            word: word,
            meaning: meaning,
            partOfSpeech: partOfSpeech
        )
    }
}
