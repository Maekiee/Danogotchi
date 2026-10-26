import Foundation
import OSLog
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

    func makeSetActiveBookUseCase() -> SetActiveBookUseCase {
        return DefaultSetActiveBookUseCase(vocabBookRepository: vocabBookRepository)
    }

    func makeFetchVocabsUseCase() -> FetchVocabsUseCase {
        return DefaultFetchVocabsUseCase(
            vocabBookRepository: vocabBookRepository,
            learningHistoryRepository: makeLearningHistoryRepository()
        )
    }

    func makeToggleSaveVocabUseCase() -> ToggleSaveVocabUseCase {
        return DefaultToggleSaveVocabUseCase(
            vocabBookRepository: vocabBookRepository,
            vocabRepository: makeVocabRepository()
        )
    }

    func makeSearchThemeViewModel() -> SearchThemeViewModel {
        return SearchThemeViewModel(
            searchThemeUseCase: DefaultSearchThemeUseCase(
                repository: DefaultSearchThemeRepository(apiClient: apiClient)
            ),
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

/// Composition Root. 앱 스코프 인스턴스를 여기서만 생성하고, 기능별 컨테이너를 만들어 넘긴다.
final class AppDIContainer {
    private let dependencies: AppDependencies

    /// screenPixelSize는 SceneDelegate가 연결된 UIWindowScene.screen에서 읽어 넘긴다
    /// window는 화면 모드를 걸 앱 창이다
    init(screenPixelSize: CGSize, window: UIWindow) {
        let coreDataStack = CoreDataStack()
        dependencies = AppDependencies(
            screenPixelSize: screenPixelSize,
            coreDataStack: coreDataStack,
            apiClient: DefaultApiClient(),
            speechSynthesizer: SystemSpeechSynthesizer(),
            themeImageStorage: ImageFileStorage(directoryName: "ThemeImage"),
            userSettingsRepository: DefaultUserSettingsRepository(),
            vocabBookRepository: DefaultVocabBookRepository(context: coreDataStack.viewContext),
            petRepository: DefaultPetRepository(context: coreDataStack.viewContext),
            appearanceApplier: WindowAppearanceApplier(window: window),
            reportError: { CrashReporter.record($0) }
        )
    }

    func makeDatabasePreparer() -> DatabasePreparing {
        return CoreDataPreparer(stack: dependencies.coreDataStack)
    }

    func makeStudyReminderUseCase() -> StudyReminderUseCase {
        return dependencies.makeStudyReminderUseCase()
    }

    func makeOnboardingProgressUseCase() -> OnboardingProgressUseCase {
        return dependencies.makeOnboardingProgressUseCase()
    }

    func makeAppearanceModeUseCase() -> AppearanceModeUseCase {
        return dependencies.makeAppearanceModeUseCase()
    }

    func makeOnboardingDIContainer() -> OnboardingDIContainer {
        return OnboardingDIContainer(dependencies: dependencies)
    }

    func makeMainDIContainer() -> MainDIContainer {
        return MainDIContainer(dependencies: dependencies)
    }
}

#if DEBUG
extension AppDIContainer {
    /// UI 테스트 전용 — 온보딩을 건너뛰고 여행 단어장을 학습 중인 메인 화면 상태를 만든다
    func seedMainFlowForUITesting() throws {
        try seedThemeSelectedForUITesting()
        _ = try DefaultCreatePetUseCase(petRepository: dependencies.petRepository).execute(type: .sprout, name: "테스트")
    }

    /// UI 테스트 전용 — 관심사·테마까지만 고른 상태. 펫이 없어 온보딩이 알 선택부터 이어진다
    func seedThemeSelectedForUITesting() throws {
        try makeDatabasePreparer().prepareIfNeeded()
        try dependencies.makeSetActiveBookUseCase().execute(topic: .travel)
        // 없는 파일명만 지정 — 원본 URL이 없어 복구 다운로드가 일어나지 않는다
        dependencies.userSettingsRepository.currentThemeImageFileName = "ui-test-theme.png"
    }

    /// UI 테스트 전용 — 주어진 이미지를 실제 테마 파일로 저장하고 배경으로 지정한다
    func seedThemeImageForUITesting(_ data: Data) throws {
        let fileName = "ui-test-solid-theme.png"
        try dependencies.themeImageStorage.save(data, fileName: fileName)
        dependencies.userSettingsRepository.currentThemeImageFileName = fileName
    }
}
#endif
