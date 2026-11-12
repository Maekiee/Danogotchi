import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class OnboardingInterestViewModelTests: XCTestCase {
    func test_interestCardsExcludeMyBookAndStartUnselected() throws {
        let screen = try InterestTestScreen()
        XCTAssertEqual(screen.items.map(\.topic), BookTopic.allCases.filter { $0 != .myBook })
        XCTAssertFalse(screen.items.contains(where: \.isSelected))
        XCTAssertEqual(screen.isNextEnabled, false)
    }

    func test_selectionMarksOneCardAndReselectingKeepsIt() throws {
        let screen = try InterestTestScreen()
        screen.select.accept(.travel)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.travel])
        XCTAssertEqual(screen.isNextEnabled, true)

        screen.select.accept(.travel)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.travel])

        screen.select.accept(.life)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.life])
    }

    func test_nextWithoutSelectionDoesNothing() throws {
        let screen = try InterestTestScreen()
        screen.next.accept(())
        XCTAssertEqual(screen.finished, 0)
        XCTAssertTrue(screen.remote.fetchedKeys.isEmpty)
        XCTAssertTrue(try screen.books.readActiveBooks().isEmpty)
    }

    func test_nextDownloadsSelectedTopicA1ThenFinishes() async throws {
        let screen = try InterestTestScreen()
        let serverWords = makeServerVocabs(lifeA1, words: ["breakfast", "laundry"])
        screen.remote.vocabs[lifeA1] = serverWords
        screen.select.accept(.life)

        screen.next.accept(())
        // 받는 동안 다음 버튼이 막힌다
        XCTAssertEqual(screen.isLoading, true)
        XCTAssertEqual(screen.isNextEnabled, false)
        XCTAssertEqual(screen.finished, 0)
        await waitUntil { screen.finished == 1 }

        XCTAssertTrue(screen.alerts.isEmpty)
        XCTAssertEqual(screen.isLoading, false)
        XCTAssertEqual(screen.remote.fetchedKeys, [lifeA1])
        let active = try screen.books.readActiveBooks()
        XCTAssertEqual(active.map(\.key), [lifeA1])
        XCTAssertEqual(active.first?.vocabList.map(\.id), serverWords.map(\.id))
    }

    func test_downloadFailureAlertsAndStaysThenRetrySucceeds() async throws {
        let screen = try InterestTestScreen()
        screen.remote.vocabs[travelA1] = makeServerVocabs(travelA1, words: ["airport"])
        screen.remote.vocabsError = URLError(.notConnectedToInternet)
        screen.select.accept(.travel)

        screen.next.accept(())
        await waitUntil { !screen.alerts.isEmpty }
        XCTAssertEqual(screen.alerts, [String(localized: "단어장을 받지 못했어요. 네트워크 연결을 확인하고 다시 시도해주세요.")])
        XCTAssertEqual(screen.finished, 0)
        XCTAssertEqual(screen.isNextEnabled, true)
        XCTAssertTrue(try screen.books.readActiveBooks().isEmpty)

        screen.remote.vocabsError = nil
        screen.next.accept(())
        await waitUntil { screen.finished == 1 }
        XCTAssertEqual(screen.alerts.count, 1)
        XCTAssertEqual(try screen.books.readActiveBooks().map(\.key), [travelA1])
    }

    func test_selectionWhileDownloadingIsIgnored() async throws {
        let screen = try InterestTestScreen()
        screen.remote.vocabs[lifeA1] = makeServerVocabs(lifeA1, words: ["breakfast"])
        screen.select.accept(.life)
        screen.next.accept(())

        screen.select.accept(.business)
        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.topic), [.life])
        await waitUntil { screen.finished == 1 }

        XCTAssertEqual(screen.remote.fetchedKeys, [lifeA1])
        XCTAssertEqual(try screen.books.readActiveBooks().map(\.key), [lifeA1])
    }

    func test_choosingAnotherTopicAgainKeepsOnlyItActiveAndKeepsEarlierWords() async throws {
        let screen = try InterestTestScreen()
        screen.remote.vocabs[travelA1] = makeServerVocabs(travelA1, words: ["airport"])
        screen.remote.vocabs[lifeA1] = makeServerVocabs(lifeA1, words: ["breakfast"])
        screen.select.accept(.travel)
        screen.next.accept(())
        await waitUntil { screen.finished == 1 }

        // 온보딩을 다시 해 다른 주제를 고른 상황
        screen.select.accept(.life)
        screen.next.accept(())
        await waitUntil { screen.finished == 2 }

        XCTAssertEqual(try screen.books.readActiveBooks().map(\.key), [lifeA1])
        let travel = try XCTUnwrap(screen.books.readBookSummary(key: travelA1))
        XCTAssertFalse(travel.isActive)
        XCTAssertEqual(try screen.books.fetchVocabs(inBookId: travel.id).map(\.word), ["airport"])
    }
}

@MainActor
private final class InterestTestScreen {
    let books: DefaultVocabBookRepository
    let remote = ControlledRemoteVocabBookRepository()
    let select = PublishRelay<BookTopic>()
    let next = PublishRelay<Void>()
    private(set) var items: [OnboardingInterestItem] = []
    private(set) var isNextEnabled: Bool?
    private(set) var isLoading: Bool?
    private(set) var finished = 0
    private(set) var alerts: [String] = []
    private let viewModel: OnboardingInterestViewModel
    private let bag = DisposeBag()

    init() throws {
        let context = makeInMemoryContext()
        books = DefaultVocabBookRepository(context: context)
        // 첫 설치 상태 — 나의 단어장만 있고 추천 단어장은 서버에서 받는다
        try DatabaseSeeder.seedIfNeeded(context: context)
        viewModel = OnboardingInterestViewModel(selectInterestUseCase: DefaultSelectInterestUseCase(
            setActiveBookUseCase: DefaultSetActiveBookUseCase(vocabBookRepository: books, remoteVocabBookRepository: remote),
            vocabBookRepository: books
        ))
        let output = viewModel.transform(input: .init(topicSelected: select.asObservable(), nextTapped: next.asObservable()))
        output.interestItems.drive(onNext: { [weak self] in self?.items = $0 }).disposed(by: bag)
        output.isNextEnabled.drive(onNext: { [weak self] in self?.isNextEnabled = $0 }).disposed(by: bag)
        output.isLoading.drive(onNext: { [weak self] in self?.isLoading = $0 }).disposed(by: bag)
        output.didFinish.emit(onNext: { [weak self] in self?.finished += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
