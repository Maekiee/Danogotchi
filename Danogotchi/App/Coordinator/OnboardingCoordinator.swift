import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidComplete()
}

final class OnboardingCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: OnboardingCoordinatorDelegate?
    private let container: AppDIContainer

    init(navigationController: UINavigationController,
         container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        showInterestSelection()
    }

    private func showInterestSelection() {
        let vm = container.makeOnboardingInterestViewModel()
        let vc = OnboardingInterestViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showSearchTheme() {
        let vm = container.makeSearchThemeViewModel(mode: .onboarding)
        let vc = SearchThemeViewController(mode: .onboarding, viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }

    private func showEggSelection() {
        let vm = container.makeOnboardingEggSelectionViewModel()
        let vc = OnboardingEggSelectionViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
}

extension OnboardingCoordinator: OnboardingInterestViewControllerDelegate {
    func onboardingInterestDidFinish() {
        showSearchTheme()
    }
}

extension OnboardingCoordinator: SearchThemeViewControllerDelegate {
    func didSelectTheme() {
        showEggSelection()
    }
}

extension OnboardingCoordinator: OnboardingEggSelectionViewControllerDelegate {
    // C-2에서 이름 지정 화면 push로 교체된다. 지금 완료해도 펫 없이 메인으로 가는 기존 동작과 같다.
    func onboardingEggSelectionDidFinish(type: PetType) {
        delegate?.onboardingDidComplete()
    }
}
