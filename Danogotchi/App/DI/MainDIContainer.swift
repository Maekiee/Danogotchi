import Foundation
import OSLog

final class MainDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    /// 탐색 배경 디코딩 상한 — 화면 세로 픽셀 이상은 필요 없다
    var backgroundMaxPixelSize: Int { Int(dependencies.screenPixelSize.height) }

    // MARK: - 자식 기능 컨테이너
    func makeLibraryDIContainer() -> LibraryDIContainer {
        return LibraryDIContainer(dependencies: dependencies)
    }

    func makeSettingDIContainer() -> SettingDIContainer {
        return SettingDIContainer(dependencies: dependencies)
    }

    func makeQuizDIContainer() -> QuizDIContainer {
        return QuizDIContainer(dependencies: dependencies)
    }

    // MARK: - Explore
    func makeExploreVocabViewModel() -> ExploreVocabViewModel {
        return ExploreVocabViewModel(
            fetchVocabsUseCase: dependencies.makeFetchVocabsUseCase(),
            startQuizUseCase: dependencies.makeStartQuizUseCase(),
            toggleSaveVocabUseCase: dependencies.makeToggleSaveVocabUseCase(),
            observeThemeUseCase: DefaultObserveThemeUseCase(
                themeImageRepository: dependencies.makeThemeImageRepository(),
                onRestoreFailed: { error in
                    AppLogger.network.error("테마 이미지 복구 실패: \(String(describing: error), privacy: .public)")
                }
            ),
            speechSynthesizer: dependencies.speechSynthesizer
        )
    }

    // MARK: - Character
    func makeCharacterViewModel() -> CharacterViewModel {
        let petRepository = dependencies.petRepository
        return CharacterViewModel(
            fetchPetStateUseCase: DefaultFetchPetStateUseCase(petRepository: petRepository),
            carePetUseCase: DefaultCarePetUseCase(petRepository: petRepository),
            levelUpPetUseCase: DefaultLevelUpPetUseCase(petRepository: petRepository),
            // dev 빌드 테스트 버튼용 — 요구 경험치를 건너뛴다
            adjustPetLevelUseCase: DefaultAdjustPetLevelUseCase(petRepository: petRepository),
            revivePetUseCase: DefaultRevivePetUseCase(petRepository: petRepository),
            fetchCurrentWeatherUseCase: DefaultFetchCurrentWeatherUseCase(
                locationProvider: DeviceLocationProvider(),
                weatherRepository: DefaultWeatherRepository(apiClient: dependencies.apiClient)
            )
        )
    }

    // MARK: - StudyReport
    func makeStudyReportFeature(
        onClose: @escaping @MainActor @Sendable () -> Void,
        onNavigate: @escaping @MainActor @Sendable (StudyReportDestination) -> Void
    ) -> StudyReportFeature {
        #if DEBUG
        if let feature = UITestingSupport.makeStudyReportFeatureIfRequested(onClose: onClose, onNavigate: onNavigate) {
            return feature
        }
        #endif
        let repository = DefaultLearningHistoryRepository(
            context: dependencies.coreDataStack.viewContext,
            reportContext: dependencies.coreDataStack.newBackgroundContext()
        )
        let useCase: FetchStudyReportUseCase = DefaultFetchStudyReportUseCase(repository: repository)
        return StudyReportFeature(
            fetch: { period, now, calendar in
                try await useCase.execute(period: period, now: now, calendar: calendar)
            },
            reportError: { [reportError = dependencies.reportError] error in
                AppLogger.database.error("학습 리포트 조회 실패: \(String(describing: error), privacy: .public)")
                reportError(error)
            },
            onClose: onClose,
            onNavigate: onNavigate
        )
    }
}
