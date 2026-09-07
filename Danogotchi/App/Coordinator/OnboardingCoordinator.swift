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
        // 테마까지 끝냈는데 펫이 없는 상태(테마 직후 강제 종료)면 관심사·테마를 반복하지 않는다
        if container.userInfoManager.currentThemeUrl != nil {
            showEggSelection(asRoot: true)
        } else {
            showInterestSelection()
        }
    }

    private func showInterestSelection() {
        let vm = container.makeOnboardingInterestViewModel()
        let vc = OnboardingInterestViewController(viewModel: vm)
        vc.delegate = self
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showSearchTheme() {
        let vm = container.makeSearchThemeViewModel()
        let vc = SearchThemeViewController(mode: .onboarding, viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }

    /// 재진입으로 알 선택이 첫 화면이 되면 push할 대상이 없어 루트로 세운다.
    private func showEggSelection(asRoot: Bool = false) {
        let vm = container.makeEggSelectionViewModel()
        let vc = EggSelectionViewController(viewModel: vm)
        vc.delegate = self

        if asRoot {
            navigationController.setViewControllers([vc], animated: false)
        } else {
            navigationController.pushViewController(vc, animated: true)
        }
    }

    private func showPetName(type: PetType) {
        let vm = container.makeOnboardingPetNameViewModel(petType: type)
        let vc = OnboardingPetNameViewController(viewModel: vm)
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
        do {
            if try container.makeIsPetCreatedUseCase().execute() {
                delegate?.onboardingDidComplete()
            } else {
                showEggSelection()
            }
        } catch {
            AlertPresenter.showNotificationAlert(
                on: navigationController,
                title: "데이터 조회 실패",
                message: "데이터를 불러오지 못했어요. 다시 시도해주세요.",
                confirmTitle: "재시도"
            ) { [weak self] in self?.didSelectTheme() }
        }
    }
}

extension OnboardingCoordinator: EggSelectionViewControllerDelegate {
    func eggSelectionDidFinish(type: PetType) {
        showPetName(type: type)
    }
}

extension OnboardingCoordinator: OnboardingPetNameViewControllerDelegate {
    func onboardingPetNameDidFinish() {
        delegate?.onboardingDidComplete()
    }
}
