import UIKit

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let window: UIWindow
    private let container: DIContainer
    
    init(window: UIWindow, container: DIContainer) {
        self.window = window
        self.navigationController = UINavigationController()
        self.container = container
    }
}


extension AppCoordinator {
    func start() {
        if UserInfoManager.shared.currentThemeUrl != nil {
            startMainFlow()
        } else {
            startOnBoardingFlow()
        }
        
        window.makeKeyAndVisible()
    }
    
    func switchToMainScene() {
//        let vm = WordTabViewModel()
        let vm = container.makeWordTabViewModel()
        window.rootViewController = WordTabViewController(viewModel: vm)
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) { }
    }
    
    private func startMainFlow() {
//        let vm = WordTabViewModel()
        let vm = container.makeWordTabViewModel()
        window.rootViewController =  WordTabViewController(viewModel: vm)
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

extension AppCoordinator: OnboardingCoordinatorDelegate {
    func onboardingDidComplete() {
        childCoordinators.removeAll { $0 is OnboardingCoordinator }
        switchToMainScene()
    }
}
