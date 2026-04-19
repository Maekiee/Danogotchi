import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidComplete()
}

final class OnboardingCoordinator: Coordinator, SearchThemeViewControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: OnboardingCoordinatorDelegate?
    private let container: DIContainer
    
    init(navigationController: UINavigationController,
         container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }
    
    func start() {
        let vc = SearchThemeViewController(
            mode: .onboarding,
            viewModel: container.makeSearchThemeViewModel(mode: .onboarding)
        )
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
        
    }
}

extension OnboardingCoordinator {
    func didSelectTheme() {
        delegate?.onboardingDidComplete()
    }
    
    func didTapBack() {
        print("")
    }
}
