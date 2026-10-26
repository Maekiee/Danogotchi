import OSLog
import UIKit

final class AppFlowCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let window: UIWindow
    private let container: AppDIContainer
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.navigationController = UINavigationController()
        self.container = container
    }
}


extension AppFlowCoordinator {
    func start() {
        // 첫 화면이 보이기 전에 건다 — DB 준비가 실패해 재시도 화면이 떠도 저장된 모드로 보인다
        container.makeAppearanceModeUseCase().applySaved()

        do {
            try container.makeDatabasePreparer().prepareIfNeeded()

            // 알림 재예약은 부가 기능이다 — 실패해도 앱 진입을 막지 않는다.
            do {
                try container.makeStudyReminderUseCase().refresh()
            } catch {
                AppLogger.push.error("학습 알림 재예약 실패: \(String(describing: error), privacy: .public)")
            }

            if try container.makeOnboardingProgressUseCase().isComplete() {
                startMainFlow()
            } else {
                startOnBoardingFlow()
            }
            window.makeKeyAndVisible()
        } catch {
            let retryViewController = UIViewController()
            retryViewController.view.backgroundColor = AppColor.background
            window.rootViewController = retryViewController
            window.makeKeyAndVisible()
            DispatchQueue.main.async { [weak self, weak retryViewController] in
                guard let retryViewController else { return }
                AlertPresenter.showNotificationAlert(
                    on: retryViewController,
                    title: String(localized: "데이터 준비 실패"),
                    message: String(localized: "데이터를 준비하지 못했어요. 다시 시도해주세요."),
                    confirmTitle: String(localized: "재시도")
                ) { [weak self] in self?.start() }
            }
        }
    }

    func switchToMainScene() {
        startMainFlow()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) { }
    }
    
    private func startMainFlow() {
        let nav = UINavigationController()
        nav.isNavigationBarHidden = true
        let mainCoordinator = MainCoordinator(
            container: container.makeMainDIContainer(),
            navigationController: nav
        )
        addChild(mainCoordinator)
        mainCoordinator.start()
        window.rootViewController = nav
    }
    
    private func startOnBoardingFlow() {
        let nav = UINavigationController()
        nav.isNavigationBarHidden = true
        let onboardingCoordinator = OnboardingCoordinator(
            navigationController: nav,
            container: container.makeOnboardingDIContainer()
        )
        onboardingCoordinator.delegate = self
        addChild(onboardingCoordinator)
        onboardingCoordinator.start()
        window.rootViewController = nav
    }
}

extension AppFlowCoordinator: OnboardingCoordinatorDelegate {
    func onboardingDidComplete() {
        childCoordinators.removeAll { $0 is OnboardingCoordinator }
        switchToMainScene()
    }
}
