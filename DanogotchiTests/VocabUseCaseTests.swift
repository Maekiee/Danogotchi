import XCTest
@testable import Danogotchi

final class VocabUseCaseTests: XCTestCase {

    func test_executeActive는_학습중_추천단어장에_이력과_저장상태를_합친다() throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let travelBook = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let savedWord = try sut.books.addVocab(
            bookId: travelBook.id,
            word: "airport",
            meaning: "공항",
            bookType: .travel,
            level: .a1,
            partOfSpeech: .noun
        )
        let unsavedWord = try sut.books.addVocab(
            bookId: travelBook.id,
            word: "depart",
            meaning: "출발하다",
            bookType: .travel,
            level: .a1,
            partOfSpeech: .verb
        )
        _ = try sut.books.addVocab(bookId: myBook.id, from: savedWord)
        try sut.histories.addHistory(makeQuizAnswer(savedWord))
        try sut.histories.addHistory(makeQuizAnswer(savedWord, isCorrect: false))
        try sut.books.setActive(id: travelBook.id, isActive: true)

        let items = try sut.useCase.executeActive()
        let itemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.word.id, $0) })
        let savedItem = try XCTUnwrap(itemsById[savedWord.id])
        let unsavedItem = try XCTUnwrap(itemsById[unsavedWord.id])

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(savedItem.learningCount, 2)
        XCTAssertEqual(savedItem.accuracy, 0.5, accuracy: 0.001)
        XCTAssertTrue(savedItem.isSaved)
        XCTAssertEqual(unsavedItem.learningCount, 0)
        XCTAssertFalse(unsavedItem.isSaved)
    }

    func test_executeActive는_학습중_단어장이_없으면_빈_배열을_반환한다() throws {
        XCTAssertTrue(try makeSUT().useCase.executeActive().isEmpty)
    }

    func test_executeActive는_학습중_단어장을_합치고_원본이_있는_저장_복사본은_뺀다() throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let airport = try sut.books.addVocab(bookId: travel.id, word: "airport", meaning: "공항",
                                             bookType: .travel, level: .a1, partOfSpeech: .noun)
        let copy = try sut.books.addVocab(bookId: myBook.id, from: airport)
        let own = try sut.books.addVocab(bookId: myBook.id, word: "apple", meaning: "사과",
                                         bookType: .myBook, level: nil, partOfSpeech: .noun)
        try sut.books.setActive(id: travel.id, isActive: true)
        try sut.books.setActive(id: myBook.id, isActive: true)

        let items = try sut.useCase.executeActive()

        XCTAssertEqual(Set(items.map(\.word.id)), [airport.id, own.id])
        XCTAssertFalse(items.contains { $0.word.id == copy.id })
        XCTAssertEqual(items.first { $0.word.id == airport.id }?.isSaved, true)
        XCTAssertEqual(items.first { $0.word.id == own.id }?.isSaved, false)

        // 원본 단어장을 끄면 복사본이 나의 단어장 단어로 보인다
        try sut.books.setActive(id: travel.id, isActive: false)
        XCTAssertEqual(Set(try sut.useCase.executeActive().map(\.word.id)), [copy.id, own.id])
    }

    func test_isActiveBook은_학습중_단어장일때만_true다() throws {
        let sut = makeSUT()
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        _ = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)
        try sut.books.setActive(id: travel.id, isActive: true)
        let useCase = DefaultIsActiveBookUseCase(vocabBookRepository: sut.books)

        XCTAssertTrue(try useCase.execute(key: travelA1))
        XCTAssertFalse(try useCase.execute(key: VocabBookKey(topic: .emotion, level: .a1)))
        XCTAssertFalse(try useCase.execute(key: lifeA1))
        XCTAssertFalse(try useCase.execute(key: VocabBookKey(topic: .travel, level: .a2)))
    }

    func test_setActive는_단어장마다_독립적으로_켜고_끈다() throws {
        let sut = makeSUT()
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let emotion = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)

        try sut.books.setActive(id: travel.id, isActive: true)
        try sut.books.setActive(id: emotion.id, isActive: true)
        XCTAssertEqual(try sut.books.readActiveBooks().map(\.id), [travel.id, emotion.id])

        try sut.books.setActive(id: travel.id, isActive: false)
        XCTAssertEqual(try sut.books.readActiveBooks().map(\.id), [emotion.id])
    }

    @MainActor
    func test_setActiveBook은_받지_않은_단어장을_서버_ID_그대로_저장하고_학습중으로_둔다() async throws {
        let sut = makeSUT()
        let serverWords = makeServerVocabs(businessA1, words: ["meeting", "invoice"])
        sut.remote.vocabs[businessA1] = serverWords

        try await sut.setActive.execute(key: businessA1, isActive: true, loaded: [])

        let book = try XCTUnwrap(sut.books.readBookSummary(key: businessA1))
        let words = try sut.books.fetchVocabs(inBookId: book.id)
        XCTAssertTrue(book.isActive)
        XCTAssertEqual(words.map(\.id), serverWords.map(\.id))
        XCTAssertEqual(words.map(\.word), ["meeting", "invoice"])
        XCTAssertEqual(sut.remote.fetchedKeys, [businessA1])
    }

    @MainActor
    func test_setActiveBook은_화면이_받아_둔_단어가_있으면_서버를_읽지_않고_저장한다() async throws {
        let sut = makeSUT()
        let loaded = makeServerVocabs(businessA1, words: ["meeting", "invoice"])

        try await sut.setActive.execute(key: businessA1, isActive: true, loaded: loaded)

        let book = try XCTUnwrap(sut.books.readBookSummary(key: businessA1))
        XCTAssertTrue(book.isActive)
        XCTAssertEqual(try sut.books.fetchVocabs(inBookId: book.id).map(\.id), loaded.map(\.id))
        XCTAssertTrue(sut.remote.fetchedKeys.isEmpty)
    }

    @MainActor
    func test_setActiveBook은_서버_단어가_0개면_던지고_아무것도_저장하지_않는다() async throws {
        let sut = makeSUT()
        sut.remote.vocabs[travelA1] = []

        do {
            try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])
            XCTFail("빈 단어장은 저장하지 않아야 한다")
        } catch {
            XCTAssertEqual(error as? VocabBookDownloadError, .emptyBook)
        }
        XCTAssertTrue(try sut.books.readBookSummaries().isEmpty)
    }

    @MainActor
    func test_setActiveBook은_이미_받은_단어장을_다시_받지_않는다() async throws {
        let sut = makeSUT()
        // 서버 ID 이전 설치본 — 같은 주제·레벨이면 받은 단어장이다
        let legacy = try sut.books.createBook(title: "Travel", bookType: .travel, level: .a1)
        sut.remote.vocabs[travelA1] = makeServerVocabs(travelA1, words: ["airport"])

        try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])

        XCTAssertEqual(try sut.books.readActiveBooks().map(\.id), [legacy.id])
        XCTAssertEqual(try sut.books.readAllBooks(bookType: .travel).count, 1)
        XCTAssertTrue(sut.remote.fetchedKeys.isEmpty)
    }

    @MainActor
    func test_setActiveBook_해제는_단어를_남기고_다시_켤때_받지_않는다() async throws {
        let sut = makeSUT()
        let serverWords = makeServerVocabs(travelA1, words: ["airport", "depart"])
        sut.remote.vocabs[travelA1] = serverWords
        try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])

        try await sut.setActive.execute(key: travelA1, isActive: false, loaded: [])
        XCTAssertTrue(try sut.books.readActiveBooks().isEmpty)
        let travel = try XCTUnwrap(sut.books.readBookSummary(key: travelA1))
        XCTAssertEqual(try sut.books.fetchVocabs(inBookId: travel.id).map(\.id), serverWords.map(\.id))

        try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])
        XCTAssertEqual(try sut.books.readActiveBooks().map(\.key), [travelA1])
        XCTAssertEqual(sut.remote.fetchedKeys, [travelA1])
    }

    @MainActor
    func test_setActiveBook_해제는_받지_않은_단어장이면_아무것도_하지_않는다() async throws {
        let sut = makeSUT()

        try await sut.setActive.execute(key: travelA1, isActive: false, loaded: [])

        XCTAssertTrue(try sut.books.readAllBooks().isEmpty)
        XCTAssertTrue(sut.remote.fetchedKeys.isEmpty)
    }

    @MainActor
    func test_setActiveBook은_받는_사이_저장된_단어장을_중복_저장하지_않는다() async throws {
        let sut = makeSUT()
        sut.remote.vocabs[travelA1] = makeServerVocabs(travelA1, words: ["airport"])
        sut.remote.beforeVocabsResponse = { [books = sut.books] in
            _ = try books.importBook(key: travelA1, vocabs: [], isActive: false)
        }

        try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])

        let travelBooks = try sut.books.readAllBooks(bookType: .travel)
        XCTAssertEqual(travelBooks.count, 1)
        XCTAssertEqual(travelBooks.first?.isActive, true)
    }

    @MainActor
    func test_setActiveBook은_받기에_실패하면_던지고_아무것도_저장하지_않는다() async throws {
        let sut = makeSUT()
        sut.remote.vocabsError = URLError(.notConnectedToInternet)

        do {
            try await sut.setActive.execute(key: travelA1, isActive: true, loaded: [])
            XCTFail("받기 실패를 전달해야 한다")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertTrue(try sut.books.readAllBooks().isEmpty)
    }

    @MainActor
    func test_fetchVocabs는_받은_단어장은_로컬에서_받지_않은_단어장은_서버에서_읽는다() async throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        let airport = try sut.books.addVocab(bookId: travel.id, word: "airport", meaning: "공항",
                                             bookType: .travel, level: .a1, partOfSpeech: .noun)
        let serverWords = makeServerVocabs(businessA1, words: ["meeting", "invoice"])
        sut.remote.vocabs[businessA1] = serverWords
        // 받기 전에 저장한 서버 단어도 서버 ID로 저장 여부가 이어진다
        _ = try sut.books.addVocab(bookId: myBook.id, from: serverWords[1])

        let local = try await sut.useCase.execute(key: travelA1, loaded: [])
        XCTAssertEqual(local.map(\.word.id), [airport.id])
        XCTAssertTrue(sut.remote.fetchedKeys.isEmpty)

        let remote = try await sut.useCase.execute(key: businessA1, loaded: [])
        XCTAssertEqual(remote.map(\.word.id), serverWords.map(\.id))
        XCTAssertEqual(remote.map(\.isSaved), [false, true])
        XCTAssertEqual(sut.remote.fetchedKeys, [businessA1])
    }

    func test_toggleSaveVocab은_저장과_해제를_번갈아_한다() throws {
        let sut = makeSUT()
        let myBook = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        let word = try addTravelWord(to: sut.books)
        let useCase = DefaultToggleSaveVocabUseCase(vocabBookRepository: sut.books, vocabRepository: sut.words)

        XCTAssertTrue(try useCase.execute(vocab: word))
        XCTAssertEqual(try sut.books.findVocab(inBookId: myBook.id, sourceWordId: word.id)?.word, word.word)

        XCTAssertFalse(try useCase.execute(vocab: word))
        XCTAssertNil(try sut.books.findVocab(inBookId: myBook.id, sourceWordId: word.id))
    }

    func test_toggleSaveVocab은_나의_단어장이_없으면_entityNotFound를_던진다() throws {
        let sut = makeSUT()
        let word = try addTravelWord(to: sut.books)
        let useCase = DefaultToggleSaveVocabUseCase(vocabBookRepository: sut.books, vocabRepository: sut.words)

        XCTAssertThrowsError(try useCase.execute(vocab: word)) { error in
            XCTAssertEqual(error as? PersistenceError, .entityNotFound)
        }
    }

    func test_fetchVocabBooks는_나의_단어장_서버_순서_서버에_없는_받은_단어장_순으로_합친다() throws {
        let sut = makeSUT()
        let emotion = try sut.books.createBook(title: "감정", bookType: .emotion, level: .a1)
        let travel = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        _ = try sut.books.createBook(title: "나의 단어장", bookType: .myBook, level: nil)
        try sut.books.setActive(id: emotion.id, isActive: true)
        try sut.books.setActive(id: travel.id, isActive: true)
        let remoteBooks = [
            RemoteVocabBook(key: businessA1, wordCount: 2, order: 1),
            RemoteVocabBook(key: travelA1, wordCount: 2, order: 0),
            RemoteVocabBook(key: travelA1, wordCount: 2, order: 2)
        ]

        let cards = try DefaultFetchVocabBooksUseCase(vocabBookRepository: sut.books, remoteVocabBookRepository: sut.remote)
            .execute(remoteBooks: remoteBooks)

        let emotionA1 = VocabBookKey(topic: .emotion, level: .a1)
        XCTAssertEqual(cards.map(\.key), [VocabBookKey(topic: .myBook, level: nil), travelA1, businessA1, emotionA1])
        XCTAssertEqual(cards.filter(\.isActive).map(\.key), [travelA1, emotionA1])
    }

    @MainActor
    func test_fetchRemoteBooks는_실패를_던진다() async throws {
        let sut = makeSUT()
        sut.remote.books = .failure(URLError(.notConnectedToInternet))
        let useCase = DefaultFetchVocabBooksUseCase(vocabBookRepository: sut.books, remoteVocabBookRepository: sut.remote)

        do {
            _ = try await useCase.fetchRemoteBooks()
            XCTFail("실패를 숨기지 않아야 화면이 다시 받을 수 있다")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    @MainActor
    func test_activeBookChanged는_학습중_단어장_변경을_전달한다() async throws {
        let sut = makeSUT()
        let book = try sut.books.createBook(title: "여행", bookType: .travel, level: .a1)
        // 변경 전에 구독을 등록한다
        var changes = sut.useCase.activeBookChanged.makeAsyncIterator()

        try sut.books.setActive(id: book.id, isActive: true)

        let received: Void? = await changes.next()
        XCTAssertNotNil(received)
    }

    private struct SUT {
        let useCase: DefaultFetchVocabsUseCase
        let setActive: DefaultSetActiveBookUseCase
        let books: DefaultVocabBookRepository
        let remote: ControlledRemoteVocabBookRepository
        let histories: DefaultLearningHistoryRepository
        let words: DefaultVocabRepository
    }

    private func makeSUT() -> SUT {
        let context = makeInMemoryContext()
        let books = DefaultVocabBookRepository(context: context)
        let remote = ControlledRemoteVocabBookRepository()
        let histories = DefaultLearningHistoryRepository(context: context)
        return SUT(
            useCase: DefaultFetchVocabsUseCase(
                vocabBookRepository: books,
                remoteVocabBookRepository: remote,
                learningHistoryRepository: histories
            ),
            setActive: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            books: books,
            remote: remote,
            histories: histories,
            words: DefaultVocabRepository(context: context)
        )
    }

    private func addTravelWord(to books: DefaultVocabBookRepository) throws -> Vocab {
        let travel = try books.createBook(title: "여행", bookType: .travel, level: .a1)
        return try books.addVocab(bookId: travel.id, word: "airport", meaning: "공항",
                                  bookType: .travel, level: .a1, partOfSpeech: .noun)
    }
}
