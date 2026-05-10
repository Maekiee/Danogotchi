import UIKit
import SafariServices

protocol SettingCoordinatorDelegate: AnyObject {
    func settingCoordinatorDidFinish()
}

final class SettingCoordinator: NSObject, Coordinator {
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
        super.init()
    }
    
    func start() {
        let vm = container.makeSettingTabViewModel()
        let vc = SettingTabViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
        navigationController.presentationController?.delegate = self
    }
}

extension SettingCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.settingCoordinatorDidFinish()
    }
}

extension SettingCoordinator: SettingTabViewControllerDelegate {
    func didTapSearchTheme() {
        let vm = container.makeSearchThemeViewModel(mode: .settings)
        let vc = SearchThemeViewController(mode: .settings, viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func didTapInquiry() {
        
    }
    
    func didTapAppStore() {
        let urlString = "itms-apps://itunes.apple.com/app/6753820016"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    func didTapPrivacyPolicy() {
        let urlString = "https://nebulous-coffee-e6d.notion.site/27ef47543db2800eb0d0d6e910c09cfc?source=copy_link"
        guard let url = URL(string: urlString) else { return }
        let safariVC = SFSafariViewController(url: url)
        navigationController.present(safariVC, animated: true)
    }
    
    func didTapClose() {
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.settingCoordinatorDidFinish()
        }
    }
    
}
