import UIKit


protocol MainCoordinatorDelegate {
    
}

final class MainCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let container: DIContainer
    
    init(
        container: DIContainer,
        navigationController: UINavigationController
    ) {
        self.container = container
        self.navigationController = navigationController
    }
    
    func start() {
        let wordTabVm = container.makeWordTabViewModel()
        let wordTabVc = WordTabViewController(viewModel: wordTabVm)
        navigationController.setViewControllers([wordTabVc], animated: false)
    }
}

extension MainCoordinator {
    
}

