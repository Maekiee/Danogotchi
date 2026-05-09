import UIKit

protocol SettingCoordinatorDelegate: AnyObject {
    func settingCoordinatorDidFinish()
}

final class SettingCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: SettingCoordinatorDelegate?
    
    private let container: DIContainer
    
    init(
        container: DIContainer,
        navigationController: UINavigationController
    ) {
        self.container = container
        self.navigationController = navigationController
    }
    
    func start() {
        let vm = container.makeSettingTabViewModel()
        let vc = SettingTabViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}

extension SettingCoordinator: SettingCoordinatorDelegate {
    
    func settingCoordinatorDidFinish() {
    }
    
}

extension SettingCoordinator: SettingTabViewControllerDelegate {
    func didTapSetDamagotchi() {
        
    }
    
    func didTapSearchTheme() {
        
    }
    
    func didTapClose() {
        
    }
    
    
}
