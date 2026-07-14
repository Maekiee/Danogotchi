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

        if UserInfoManager.shared.currentThemeUrl != nil {
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
