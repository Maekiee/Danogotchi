import UIKit
import XCTest
@testable import Danogotchi

/// start()의 성공 경로는 디스크 스토어·알림 센터에 묶여 있어, 온보딩 완료 전환과 준비 실패 경로만 검증한다
@MainActor
final class AppFlowCoordinatorTests: XCTestCase {
    func test_startReportsPreparationFailureOnceAndShowsRetryScreen() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let reporter = ErrorRecorder()
        let failure = DatabasePreparationError(stage: .seed, underlying: CocoaError(.fileWriteOutOfSpace))
        let container = AppDIContainer(
            screenPixelSize: CGSize(width: 1179, height: 2556), window: window,
            databasePreparer: FailingDatabasePreparer(error: failure),
            reportError: { [reporter] in reporter.record($0) }
        )
        let coordinator = AppFlowCoordinator(window: window, container: container)

        coordinator.start()

        XCTAssertEqual(reporter.errors.count, 1, "준비 실패는 단계 정보를 붙여 한 번만 보고한다")
        let reported = try XCTUnwrap(reporter.errors.first) as NSError
        XCTAssertEqual(reported.domain, "danogotchi.database_preparation")
        XCTAssertEqual(reported.code, 4)
        XCTAssertFalse(window.rootViewController is UINavigationController, "앱 흐름 대신 재시도 화면을 띄운다")
        XCTAssertTrue(coordinator.childCoordinators.isEmpty)
    }

    func test_onboardingCompletionReplacesOnboardingWithMainFlow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = AppDIContainer(screenPixelSize: CGSize(width: 1179, height: 2556), window: window)
        let coordinator = AppFlowCoordinator(window: window, container: container)
        let onboarding = OnboardingCoordinator(navigationController: UINavigationController(),
                                               container: container.makeOnboardingDIContainer())
        coordinator.childCoordinators.append(onboarding)

        coordinator.onboardingDidComplete()

        let navigation = window.rootViewController as? UINavigationController
        XCTAssertTrue(navigation?.viewControllers.first is ExploreVocabViewController)
        XCTAssertEqual(navigation?.isNavigationBarHidden, true)
        XCTAssertFalse(coordinator.childCoordinators.contains { $0 is OnboardingCoordinator })
        XCTAssertEqual(coordinator.childCoordinators.filter { $0 is MainCoordinator }.count, 1)
    }
}

private struct FailingDatabasePreparer: DatabasePreparing {
    let error: Error
    func prepareIfNeeded() throws { throw error }
}

/// start()는 메인에서 동기로 보고한다 — 보고 클로저가 @Sendable이라 표시만 한다
private final class ErrorRecorder: @unchecked Sendable {
    private(set) var errors: [Error] = []
    func record(_ error: Error) { errors.append(error) }
}
