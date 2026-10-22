import Foundation

final class OnboardingDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    /// 사진 테마 미리보기 비율 — 저장 비율과 같은 출처
    var screenAspectRatio: CGFloat { dependencies.screenPixelSize.width / dependencies.screenPixelSize.height }

    func makeOnboardingProgressUseCase() -> OnboardingProgressUseCase {
        return dependencies.makeOnboardingProgressUseCase()
    }

    func makeOnboardingInterestViewModel() -> OnboardingInterestViewModel {
        return OnboardingInterestViewModel(setActiveBookUseCase: dependencies.makeSetActiveBookUseCase())
    }

    func makeSearchThemeViewModel() -> SearchThemeViewModel {
        return dependencies.makeSearchThemeViewModel()
    }

    func makePhotoThemeFeature(
        onThemeSaved: @escaping @MainActor @Sendable () -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void = {}
    ) -> PhotoThemeFeature {
        return dependencies.makePhotoThemeFeature(onThemeSaved: onThemeSaved, onClose: onClose)
    }

    func makeEggSelectionViewModel() -> EggSelectionViewModel {
        return EggSelectionViewModel()
    }

    func makeOnboardingPetNameViewModel(petType: PetType) -> OnboardingPetNameViewModel {
        return OnboardingPetNameViewModel(
            createPetUseCase: DefaultCreatePetUseCase(petRepository: dependencies.petRepository),
            petType: petType
        )
    }
}
