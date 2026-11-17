import Foundation

/// 온보딩 재진입 분기 전용. 펫 상태를 정산하지도 저장하지도 않는다.
protocol OnboardingProgressUseCase {
    /// 테마를 한 번이라도 지정했는가
    var hasSelectedTheme: Bool { get }
    /// 테마 선택과 펫 생성이 모두 끝났는가
    func isComplete() throws -> Bool
}

final class DefaultOnboardingProgressUseCase: OnboardingProgressUseCase {
    private let userSettings: UserSettingsRepository
    private let petRepository: PetRepository

    init(userSettings: UserSettingsRepository, petRepository: PetRepository) {
        self.userSettings = userSettings
        self.petRepository = petRepository
    }

    var hasSelectedTheme: Bool {
        return userSettings.hasSelectedTheme
    }

    func isComplete() throws -> Bool {
        return try hasSelectedTheme && petRepository.readPet() != nil
    }
}
