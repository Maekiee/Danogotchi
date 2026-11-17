import Foundation
import UIKit

/// 앱 스코프 공유 인스턴스. 기능 컨테이너가 받는 유일한 입력이다.
/// 규칙: 변경 스트림 같은 상태를 가진 리포지토리는 여기서 1개만 공유하고, 무상태 리포지토리는 호출마다 만든다.
struct AppDependencies {
    /// 연결된 화면의 픽셀 크기. 테마 저장·미리보기·배경 디코딩이 같은 값을 쓴다
    let screenPixelSize: CGSize
    let coreDataStack: CoreDataStack
    let apiClient: ApiClient
    let speechSynthesizer: SpeechSynthesizing
    let themeImageStorage: ImageFileStorage
    /// 테마 파일명 변경 스트림 보유
    let userSettingsRepository: UserSettingsRepository
    /// activeBookChanged 스트림 보유
    let vocabBookRepository: VocabBookRepository
    let petRepository: PetRepository
    /// 앱 창을 붙잡고 있어 1개만 공유
    let appearanceApplier: AppearanceApplying
    /// 표현 계층의 실패 보고. Crashlytics 호출은 조립부에만 둔다
    let reportError: @Sendable (Error) -> Void
}

// MARK: - 여러 기능이 함께 쓰는 조립 — 중복을 막기 위해 한 곳에만 둔다
extension AppDependencies {
    func makeVocabRepository() -> VocabRepository {
        return DefaultVocabRepository(context: coreDataStack.viewContext)
    }

    func makeLearningHistoryRepository() -> LearningHistoryRepository {
        return DefaultLearningHistoryRepository(context: coreDataStack.viewContext)
    }

    func makeThemeImageRepository() -> ThemeImageRepository {
        return DefaultThemeImageRepository(
            apiClient: apiClient,
            storage: themeImageStorage,
            userSettings: userSettingsRepository,
            targetPixelSize: screenPixelSize
        )
    }

    func makeStudyReminderUseCase() -> StudyReminderUseCase {
        return DefaultStudyReminderUseCase(
            userSettings: userSettingsRepository,
            learningHistoryRepository: makeLearningHistoryRepository(),
            scheduler: LocalNotificationScheduler()
        )
    }

    func makeAppearanceModeUseCase() -> AppearanceModeUseCase {
        return DefaultAppearanceModeUseCase(userSettings: userSettingsRepository, applier: appearanceApplier)
    }

    func makeOnboardingProgressUseCase() -> OnboardingProgressUseCase {
        return DefaultOnboardingProgressUseCase(
            userSettings: userSettingsRepository,
            petRepository: petRepository
        )
    }

    func makeStartQuizUseCase() -> StartQuizUseCase {
        return DefaultStartQuizUseCase(
            vocabBookRepository: vocabBookRepository,
            learningHistoryRepository: makeLearningHistoryRepository()
        )
    }

    func makeRemoteVocabBookRepository() -> RemoteVocabBookRepository {
        #if DEBUG
        if let repository = UITestingSupport.makeRemoteVocabBookRepositoryIfRequested() { return repository }
        #endif
        return FirestoreVocabBookRepository()
    }

    func makeSetActiveBookUseCase() -> SetActiveBookUseCase {
        return DefaultSetActiveBookUseCase(
            vocabBookRepository: vocabBookRepository,
            remoteVocabBookRepository: makeRemoteVocabBookRepository()
        )
    }

    func makeFetchVocabsUseCase() -> FetchVocabsUseCase {
        return DefaultFetchVocabsUseCase(
            vocabBookRepository: vocabBookRepository,
            remoteVocabBookRepository: makeRemoteVocabBookRepository(),
            learningHistoryRepository: makeLearningHistoryRepository()
        )
    }

    func makeToggleSaveVocabUseCase() -> ToggleSaveVocabUseCase {
        return DefaultToggleSaveVocabUseCase(
            vocabBookRepository: vocabBookRepository,
            vocabRepository: makeVocabRepository()
        )
    }

    private func makeSearchThemeRepository() -> SearchThemeRepository {
        #if DEBUG
        if let repository = UITestingSupport.makeSearchThemeRepositoryIfRequested() { return repository }
        #endif
        return DefaultSearchThemeRepository(apiClient: apiClient)
    }

    func makeSearchThemeViewModel() -> SearchThemeViewModel {
        return SearchThemeViewModel(
            searchThemeUseCase: DefaultSearchThemeUseCase(repository: makeSearchThemeRepository()),
            saveThemeUseCase: DefaultSaveThemeUseCase(themeImageRepository: makeThemeImageRepository()),
            reportError: reportError
        )
    }

    func makePhotoThemeFeature(
        onThemeSaved: @escaping @MainActor @Sendable () -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void = {}
    ) -> PhotoThemeFeature {
        return PhotoThemeFeature(
            savePhotoThemeUseCase: DefaultSavePhotoThemeUseCase(themeImageRepository: makeThemeImageRepository()),
            reportError: reportError,
            previewPixelSize: Int(screenPixelSize.height),
            onThemeSaved: onThemeSaved,
            onClose: onClose
        )
    }
}
