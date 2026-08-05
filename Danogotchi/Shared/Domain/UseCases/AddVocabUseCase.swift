import Foundation

protocol AddVocabUseCase {
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
