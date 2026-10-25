import UIKit
import XCTest
@testable import Danogotchi

/// start()는 디스크 스토어·알림 센터에 묶여 있어 온보딩 완료 전환만 검증한다
@MainActor
final class AppFlowCoordinatorTests: XCTestCase {
    func test_onboardingCompletionReplacesOnboardingWithMainFlow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = AppDIContainer(screenPixelSize: CGSize(width: 1179, height: 2556))
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
