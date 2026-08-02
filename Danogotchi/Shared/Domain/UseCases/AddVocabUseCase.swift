import Foundation

protocol AddVocabUseCase {
    /// 사용자가 직접 입력한 단어를 나의 단어장에 추가하고 결과를 반환한다. 실패 시 nil.
    func execute(word: String, meaning: String, partOfSpeech: PartOfSpeech) -> Vocab?
}

final class DefaultAddVocabUseCase: AddVocabUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(word: String, meaning: String, partOfSpeech: PartOfSpeech) -> Vocab? {
        guard let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first else {
            return nil
        }

        return vocabBookRepository.addVocab(
            bookId: myBook.id,
            word: word,
            meaning: meaning,
            bookType: .myBook,
            level: nil,
            partOfSpeech: partOfSpeech
        )
    }
}
