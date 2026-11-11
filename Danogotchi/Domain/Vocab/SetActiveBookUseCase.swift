import Foundation

protocol SetActiveBookUseCase {
    /// 해당 토픽의 단어장을 활성 단어장으로 지정한다. 단어장이 없으면 entityNotFound를 던진다.
    func execute(topic: BookTopic) throws
}

final class DefaultSetActiveBookUseCase: SetActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(topic: BookTopic) throws {
        guard let book = try vocabBookRepository.readAllBooks(bookType: topic).first else {
            throw PersistenceError.entityNotFound
        }
        try vocabBookRepository.setActiveBook(id: book.id)
    }
}
