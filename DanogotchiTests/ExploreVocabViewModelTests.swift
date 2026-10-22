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
