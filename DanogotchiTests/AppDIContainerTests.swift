import UIKit
import XCTest
@testable import Danogotchi

/// Composition Root가 모든 기능 컨테이너와 화면 의존성을 조립할 수 있는지 — 배선 누락은 런타임 크래시로만 드러난다
@MainActor
final class AppDIContainerTests: XCTestCase {
    func test_everyFeatureContainerBuildsItsScreens() {
        let app = AppDIContainer(screenPixelSize: CGSize(width: 1179, height: 2556), window: UIWindow())

        _ = app.makeDatabasePreparer()
        _ = app.makeStudyReminderUseCase()
        _ = app.makeAppearanceModeUseCase()
        _ = app.makeOnboardingProgressUseCase()

        let onboarding = app.makeOnboardingDIContainer()
        _ = onboarding.makeOnboardingProgressUseCase()
        _ = onboarding.makeOnboardingInterestViewModel()
        _ = onboarding.makeSearchThemeViewModel()
        _ = onboarding.makeEggSelectionViewModel()
        _ = onboarding.makeOnboardingPetNameViewModel(petType: .sprout)
        _ = onboarding.makePhotoThemeFeature(onThemeSaved: {})

        let main = app.makeMainDIContainer()
        _ = main.makeExploreVocabViewModel()
        _ = main.makeCharacterViewModel()
        _ = main.makeStudyReportFeature(onClose: {}, onNavigate: { _ in })

        let library = main.makeLibraryDIContainer()
        _ = library.makeLibraryViewModel()
        _ = library.makeVocabDetailViewModel(topic: .travel)
        _ = library.makeAddVocabViewModel()

        let quiz = main.makeQuizDIContainer()
        _ = quiz.makeQuizViewModel(quizData: QuizData(words: [], allWord: []))
        _ = quiz.makeCompleteQuizViewModel(result: QuizResult(
            correct: 0, total: 0, incorrectWords: [], experience: ExperienceGain(earned: 0, perfectBonus: 0)
        ))
        _ = quiz.makeStartQuizUseCase()

        let setting = main.makeSettingDIContainer()
        _ = setting.makeSettingTabViewModel()
        _ = setting.makeSearchThemeViewModel()
        _ = setting.makePhotoThemeFeature(onThemeSaved: {})
    }
}
