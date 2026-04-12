import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidComplete()
}

final class OnboardingCoordinator: Coordinator, SearchThemeViewControllerDelegate {
    var childCoordinators: [any Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: OnboardingCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = SearchThemeViewController()
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
