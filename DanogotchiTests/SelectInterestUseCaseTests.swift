import XCTest
@testable import Danogotchi

@MainActor
final class SelectInterestUseCaseTests: XCTestCase {
    func test_downloadFailureKeepsPreviousActiveBooks() async throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())
        let remote = ControlledRemoteVocabBookRepository()
        _ = try books.importBook(key: travelA1, vocabs: makeServerVocabs(travelA1, words: ["airport"]), isActive: true)
        remote.vocabsError = URLError(.notConnectedToInternet)
        let useCase = DefaultSelectInterestUseCase(
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            vocabBookRepository: books
        )

        do {
            try await useCase.execute(topic: .life)
            XCTFail("받기 실패를 전달해야 한다")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertEqual(try books.readBookSummaries().map(\.key), [travelA1])
        XCTAssertEqual(try books.readActiveBooks().map(\.key), [travelA1])
    }
}
