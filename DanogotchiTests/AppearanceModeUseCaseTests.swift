import XCTest
@testable import Danogotchi

final class AppearanceModeUseCaseTests: XCTestCase {
    private final class RecordingAppearanceApplier: AppearanceApplying {
        private(set) var applied: [AppearanceMode] = []
        func apply(_ mode: AppearanceMode) { applied.append(mode) }
    }

    func test_setSavesAndAppliesAndApplySavedRestoresStoredMode() {
        let settings = TestUserSettings()
        let applier = RecordingAppearanceApplier()
        let useCase = DefaultAppearanceModeUseCase(userSettings: settings, applier: applier)

        useCase.applySaved()
        XCTAssertEqual(applier.applied, [.system], "첫 실행은 시스템 설정을 따른다")

        useCase.set(.dark)
        XCTAssertEqual(settings.appearanceMode, .dark)
        XCTAssertEqual(applier.applied, [.system, .dark], "고르면 저장과 동시에 적용된다")

        // 다시 실행하면 저장된 모드가 적용된다
        DefaultAppearanceModeUseCase(userSettings: settings, applier: applier).applySaved()
        XCTAssertEqual(applier.applied.last, .dark)
    }
}
