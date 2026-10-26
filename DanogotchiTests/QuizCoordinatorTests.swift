import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class QuizCoordinatorTests: XCTestCase {
    private final class SpyDelegate: QuizCoordinatorDelegate {
        private(set) var finished = 0
        func quizCoordinatorDidFinish() { finished += 1 }
    }

    /// present·alert는 키 윈도우가 있어야 presentedViewController에 잡힌다
    private struct Fixture {
        let coordinator: QuizCoordinator
        let navigation: UINavigationController
        let delegate: SpyDelegate
        let window: UIWindow
        let words: [Vocab]
    }

    private func makeFixture() -> Fixture {
        let words = makeQuizWords(4)
        let navigation = UINavigationController()
        let delegate = SpyDelegate()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = AppDIContainer(screenPixelSize: CGSize(width: 1179, height: 2556), window: window)
            .makeMainDIContainer().makeQuizDIContainer()
        let coordinator = QuizCoordinator(container: container, navigationController: navigation,
                                          quizData: QuizData(words: words, allWord: words))
        coordinator.delegate = delegate
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        coordinator.start()
        return Fixture(coordinator: coordinator, navigation: navigation, delegate: delegate, window: window, words: words)
    }

    private func makeResult(_ fixture: Fixture, incorrect: [Vocab]) -> QuizResult {
        QuizResult(correct: 4 - incorrect.count, total: 4, incorrectWords: incorrect,
                   experience: ExperienceGain(earned: 20 * (4 - incorrect.count), perfectBonus: 0))
    }

    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 3) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return condition()
    }

    func test_startShowsQuizScreenAsRoot() {
        let fixture = makeFixture()
        XCTAssertEqual(fixture.navigation.viewControllers.count, 1)
        XCTAssertTrue(fixture.navigation.topViewController is QuizViewController)
    }

    func test_finishingActionsNotifyDelegateImmediately() {
        let fixture = makeFixture()
        let result = makeResult(fixture, incorrect: [])
        let data = QuizData(words: fixture.words, allWord: fixture.words)

        fixture.coordinator.completeQuizDidSelectAction(.finish, originalQuizData: data, result: result)
        XCTAssertEqual(fixture.delegate.finished, 1)
        fixture.coordinator.completeQuizDidSelectAction(.dismiss, originalQuizData: data, result: result)
        XCTAssertEqual(fixture.delegate.finished, 2)
        fixture.coordinator.quizDidAbortAfterSaveFailure()
        XCTAssertEqual(fixture.delegate.finished, 3)
    }

    func test_completionPresentsResultScreenFullScreen() {
        let fixture = makeFixture()
        let data = QuizData(words: fixture.words, allWord: fixture.words)

        fixture.coordinator.quizDidComplete(originalData: data, result: makeResult(fixture, incorrect: [fixture.words[0]]))

        XCTAssertTrue(waitUntil { fixture.navigation.presentedViewController is CompleteQuizViewController })
        XCTAssertEqual(fixture.navigation.presentedViewController?.modalPresentationStyle, .fullScreen)
        XCTAssertEqual(fixture.delegate.finished, 0)
    }

    func test_closeAsksForConfirmationInsteadOfFinishing() throws {
        let fixture = makeFixture()

        fixture.coordinator.quizDidTapClose()

        XCTAssertTrue(waitUntil { fixture.navigation.presentedViewController is UIAlertController })
        let alert = try XCTUnwrap(fixture.navigation.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.title, String(localized: "학습 중단"))
        XCTAssertEqual(alert.message, String(localized: "정말로 학습을 중단하시겠습니까?"))
        XCTAssertEqual(alert.actions.map(\.title), [String(localized: "취소"), String(localized: "확인")])
        XCTAssertEqual(alert.actions.map(\.style), [.cancel, .destructive])
        XCTAssertEqual(fixture.delegate.finished, 0)
    }

    func test_retryingIncorrectWordsDismissesResultAndReplacesQuiz() throws {
        let fixture = makeFixture()
        let first = try XCTUnwrap(fixture.navigation.topViewController)
        let data = QuizData(words: fixture.words, allWord: fixture.words)
        let incorrect = [fixture.words[1]]
        fixture.coordinator.quizDidComplete(originalData: data, result: makeResult(fixture, incorrect: incorrect))
        XCTAssertTrue(waitUntil { fixture.navigation.presentedViewController is CompleteQuizViewController })

        fixture.coordinator.completeQuizDidSelectAction(.retryIncorrect(words: incorrect), originalQuizData: data,
                                                        result: makeResult(fixture, incorrect: incorrect))

        XCTAssertTrue(waitUntil {
            fixture.navigation.presentedViewController == nil
                && fixture.navigation.topViewController is QuizViewController
                && fixture.navigation.topViewController !== first
        })
        XCTAssertEqual(fixture.navigation.viewControllers.count, 1)
        XCTAssertEqual(fixture.delegate.finished, 0)
    }
}
