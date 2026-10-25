import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class ExploreVocabViewModelTests: XCTestCase {
    func test_speakTappedForwardsTextToSynthesizer() {
        let screen = Screen()

        screen.speakTapped.accept("apple")
        screen.speakTapped.accept("banana")

        XCTAssertEqual(screen.synthesizer.spoken, ["apple", "banana"])
    }

    func test_speakingTextStreamDrivesOutput() async {
        let screen = Screen()
        // 스트림은 최신 값 하나만 버퍼링하므로 단계마다 전달을 기다린다
        await waitForSpeakingText(screen, toBe: [nil], "구독 즉시 현재 값")

        screen.speakTapped.accept("apple")
        await waitForSpeakingText(screen, toBe: [nil, "apple"], "발음 시작")

        screen.synthesizer.stop()
        await waitForSpeakingText(screen, toBe: [nil, "apple", nil], "발음 종료")
    }

    private func waitForSpeakingText(_ screen: Screen, toBe expected: [String?], _ step: String) async {
        let delivered = expectation(description: step)
        screen.onSpeakingText = { if $0 == expected { delivered.fulfill() } }
        await fulfillment(of: [delivered], timeout: 2)
        screen.onSpeakingText = nil
    }

    @MainActor
    private final class Screen {
        let synthesizer = RecordingSpeechSynthesizer()
        let speakTapped = PublishRelay<String>()
        var onSpeakingText: (([String?]) -> Void)?
        private var received: [String?] = []
        private let disposeBag = DisposeBag()
        // ViewModel이 해제되면 disposeBag이 구독을 끊으므로 픽스처가 붙잡는다
        private let viewModel: ExploreVocabViewModel

        init() {
            viewModel = ExploreVocabViewModel(
                fetchVocabsUseCase: StubFetchVocabsUseCase(),
                startQuizUseCase: StubStartQuizUseCase(),
                toggleSaveVocabUseCase: StubToggleSaveVocabUseCase(),
                observeThemeUseCase: StubObserveThemeUseCase(),
                speechSynthesizer: synthesizer
            )
            let output = viewModel.transform(input: ExploreVocabViewModel.Input(
                viewWillAppear: .never(),
                startLearningTapped: .never(),
                saveVocabTrigger: .never(),
                speakTapped: speakTapped.asObservable()
            ))
            output.speakingText
                .drive(with: self) { owner, text in
                    owner.received.append(text)
                    owner.onSpeakingText?(owner.received)
                }
                .disposed(by: disposeBag)
        }
    }
}

private final class RecordingSpeechSynthesizer: SpeechSynthesizing {
    private(set) var spoken: [String] = []
    private var current: String?
    private let broadcaster = AsyncBroadcaster<String?>()

    var speakingText: AsyncStream<String?> {
        broadcaster.stream(current: { self.current })
    }

    func speak(_ text: String) {
        spoken.append(text)
        update(text)
    }

    func stop() {
        update(nil)
    }

    private func update(_ text: String?) {
        current = text
        broadcaster.send(text)
    }
}

private struct StubFetchVocabsUseCase: FetchVocabsUseCase {
    var activeBookChanged: AsyncStream<Void> { AsyncStream { $0.finish() } }
    func execute(topic: BookTopic) throws -> [VocabDisplayInfo] { [] }
    func executeActive() throws -> (bookType: BookTopic, items: [VocabDisplayInfo])? { nil }
}

private struct StubStartQuizUseCase: StartQuizUseCase {
    func execute() throws -> StartQuizResult { .noWords }
}

private struct StubToggleSaveVocabUseCase: ToggleSaveVocabUseCase {
    func execute(vocab: Vocab) throws -> Bool { false }
}

private struct StubObserveThemeUseCase: ObserveThemeUseCase {
    func execute() -> AsyncStream<URL?> { AsyncStream { $0.finish() } }
}

// MARK: - 단어 로드·저장·학습 시작

@MainActor
extension ExploreVocabViewModelTests {
    func test_appearLoadsActiveBookAndShowsSaveButtonForRecommendedBooks() {
        let screen = FullScreen()
        let words = makeDisplayInfos(3)
        screen.fetch.content = .success((bookType: .travel, items: words))

        screen.appear.accept(())

        XCTAssertEqual(Set(screen.items), Set(words))
        XCTAssertEqual(screen.showsSave, true)
        XCTAssertTrue(screen.alerts.isEmpty)
    }

    func test_myBookHidesSaveButton() {
        let screen = FullScreen()
        screen.fetch.content = .success((bookType: .myBook, items: makeDisplayInfos(2)))
        screen.appear.accept(())
        XCTAssertEqual(screen.showsSave, false)
    }

    func test_missingActiveBookKeepsScreenAndReadFailureAlerts() {
        let screen = FullScreen()
        let words = makeDisplayInfos(2)
        screen.fetch.content = .success((bookType: .travel, items: words))
        screen.appear.accept(())

        // 활성 단어장이 없으면 화면을 그대로 둔다
        screen.fetch.content = .success(nil)
        screen.appear.accept(())
        XCTAssertEqual(Set(screen.items), Set(words))
        XCTAssertTrue(screen.alerts.isEmpty)

        screen.fetch.content = .failure(CocoaError(.fileReadUnknown))
        screen.appear.accept(())
        XCTAssertEqual(Set(screen.items), Set(words))
        XCTAssertEqual(screen.alerts, [String(localized: "단어를 불러오지 못했어요. 다시 시도해주세요.")])
    }

    func test_saveToggleUpdatesOnlyThatWordAndFailureAlerts() {
        let screen = FullScreen()
        let words = makeDisplayInfos(3)
        screen.fetch.content = .success((bookType: .travel, items: words))
        screen.appear.accept(())
        let target = screen.items[1]

        screen.toggle.result = .success(true)
        screen.save.accept(target)
        XCTAssertEqual(screen.items.map(\.isSaved), [false, true, false])
        XCTAssertEqual(screen.items.map(\.word.id), screen.items.map(\.word.id))
        XCTAssertEqual(screen.toggle.toggled, [target.word.id])

        screen.toggle.result = .failure(CocoaError(.fileWriteOutOfSpace))
        screen.save.accept(screen.items[1])
        XCTAssertEqual(screen.items.map(\.isSaved), [false, true, false])
        XCTAssertEqual(screen.alerts, [String(localized: "저장하지 못했어요. 다시 시도해주세요.")])
    }

    func test_startLearningMapsEveryOutcome() {
        let screen = FullScreen()
        let words = makeQuizWords(4)
        screen.start.result = .success(.success(QuizData(words: words, allWord: words)))
        screen.startLearning.accept(())
        XCTAssertEqual(screen.quizzes.map { $0.words.map(\.id) }, [words.map(\.id)])

        screen.start.result = .success(.noWords)
        screen.startLearning.accept(())
        screen.start.result = .success(.notEnoughWords)
        screen.startLearning.accept(())
        screen.start.result = .failure(CocoaError(.fileReadUnknown))
        screen.startLearning.accept(())

        XCTAssertEqual(screen.quizzes.count, 1)
        XCTAssertEqual(screen.alerts, [
            String(localized: "학습할 단어가 없습니다."),
            String(localized: "최소 4개 이상의 단어가 필요합니다."),
            String(localized: "학습을 시작하지 못했어요. 다시 시도해주세요."),
        ])
    }

    func test_sameWordSetKeepsShuffledOrderAndChangedSetReshuffles() {
        let screen = FullScreen()
        let words = makeDisplayInfos(6)
        screen.fetch.content = .success((bookType: .travel, items: words))
        screen.appear.accept(())
        let firstOrder = screen.items.map(\.word.id)
        XCTAssertEqual(Set(firstOrder), Set(words.map(\.word.id)))

        // 같은 구성이면 입력 순서가 달라도 기존 순서를 유지한다
        screen.fetch.content = .success((bookType: .travel, items: words.reversed()))
        screen.appear.accept(())
        XCTAssertEqual(screen.items.map(\.word.id), firstOrder)

        let changed = words + makeDisplayInfos(1)
        screen.fetch.content = .success((bookType: .travel, items: changed))
        screen.appear.accept(())
        XCTAssertEqual(Set(screen.items.map(\.word.id)), Set(changed.map(\.word.id)))
        XCTAssertEqual(screen.items.count, 7)
    }

    func test_activeBookChangeReloadsOnMain() async {
        let screen = FullScreen()
        screen.fetch.content = .success((bookType: .life, items: makeDisplayInfos(2)))
        let reloaded = expectation(description: "active book change reloads words")
        screen.onItems = { items in
            guard !items.isEmpty else { return }
            XCTAssertTrue(Thread.isMainThread)
            reloaded.fulfill()
        }

        screen.fetch.notifyActiveBookChanged()

        await fulfillment(of: [reloaded], timeout: 2)
        XCTAssertEqual(screen.fetch.executions, 1)
        XCTAssertEqual(screen.showsSave, true)
    }

    private func makeDisplayInfos(_ count: Int) -> [VocabDisplayInfo] {
        makeQuizWords(count).map { VocabDisplayInfo(word: $0, learningCount: 0, accuracy: 0) }
    }
}

@MainActor
private final class FullScreen {
    let fetch = ControlledFetchVocabsUseCase()
    let start = ControlledStartQuizUseCase()
    let toggle = ControlledToggleSaveVocabUseCase()
    let appear = PublishRelay<Void>()
    let startLearning = PublishRelay<Void>()
    let save = PublishRelay<VocabDisplayInfo>()
    private(set) var items: [VocabDisplayInfo] = []
    private(set) var showsSave: Bool?
    private(set) var quizzes: [QuizData] = []
    private(set) var alerts: [String] = []
    var onItems: (([VocabDisplayInfo]) -> Void)?
    private let viewModel: ExploreVocabViewModel
    private let disposeBag = DisposeBag()

    init() {
        viewModel = ExploreVocabViewModel(
            fetchVocabsUseCase: fetch,
            startQuizUseCase: start,
            toggleSaveVocabUseCase: toggle,
            observeThemeUseCase: StubObserveThemeUseCase(),
            speechSynthesizer: RecordingSpeechSynthesizer()
        )
        let output = viewModel.transform(input: ExploreVocabViewModel.Input(
            viewWillAppear: appear.asObservable(),
            startLearningTapped: startLearning.asObservable(),
            saveVocabTrigger: save.asObservable(),
            speakTapped: .never()
        ))
        output.wordItems.drive(onNext: { [weak self] items in
            self?.items = items
            self?.onItems?(items)
        }).disposed(by: disposeBag)
        output.showsSaveButton.drive(onNext: { [weak self] in self?.showsSave = $0 }).disposed(by: disposeBag)
        output.startQuiz.emit(onNext: { [weak self] in self?.quizzes.append($0) }).disposed(by: disposeBag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: disposeBag)
    }
}

private final class ControlledFetchVocabsUseCase: FetchVocabsUseCase {
    var content: Result<(bookType: BookTopic, items: [VocabDisplayInfo])?, Error> = .success(nil)
    private(set) var executions = 0
    private var continuation: AsyncStream<Void>.Continuation?

    var activeBookChanged: AsyncStream<Void> {
        AsyncStream { [weak self] continuation in self?.continuation = continuation }
    }

    func execute(topic: BookTopic) throws -> [VocabDisplayInfo] { try content.get()?.items ?? [] }

    func executeActive() throws -> (bookType: BookTopic, items: [VocabDisplayInfo])? {
        executions += 1
        return try content.get()
    }

    func notifyActiveBookChanged() { continuation?.yield(()) }
}

private final class ControlledStartQuizUseCase: StartQuizUseCase {
    var result: Result<StartQuizResult, Error> = .success(.noWords)
    func execute() throws -> StartQuizResult { try result.get() }
}

private final class ControlledToggleSaveVocabUseCase: ToggleSaveVocabUseCase {
    var result: Result<Bool, Error> = .success(true)
    private(set) var toggled: [UUID] = []
    func execute(vocab: Vocab) throws -> Bool {
        toggled.append(vocab.id)
        return try result.get()
    }
}
