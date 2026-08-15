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
        DatabaseSeeder.seedIfNeeded(context: container.coreDataStack.viewContext)

        // 테마와 펫이 모두 있어야 온보딩 완료다. 펫만 없으면 OnboardingCoordinator가 알 선택부터 시작한다.
        let isOnboardingComplete = UserInfoManager.shared.currentThemeUrl != nil
            && container.makeIsPetCreatedUseCase().execute()

        if isOnboardingComplete {
            startMainFlow()
        } else {
            startOnBoardingFlow()
        }
        
        window.makeKeyAndVisible()
    }
    
    func switchToMainScene() {
        startMainFlow()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) { }
    }
    
    private func startMainFlow() {
        let nav = UINavigationController()
        nav.isNavigationBarHidden = true
        let mainCoordinator = MainCoordinator(
            container: container,
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
            container: container
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
