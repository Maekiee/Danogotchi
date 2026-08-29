import Foundation

final class AppDIContainer {
    let userInfoManager: UserInfoProtocol
    let ttsManager: TTSManager
    let coreDataStack: CoreDataStack
    let apiClient:ApiClient
    let vocabBookRepository: VocabBookRepository
    let petRepository: PetRepository

    init() {
        userInfoManager = UserInfoManager.shared
        ttsManager = TTSManager.shared
        coreDataStack = CoreDataStack.shared
        apiClient = DefaultApiClient()
        vocabBookRepository = DefaultVocabBookRepository(context: coreDataStack.viewContext)
        petRepository = DefaultPetRepository(context: coreDataStack.viewContext)
    }
}

// MARK: - Explore / CreateWord
extension AppDIContainer {
    
    func makeExploreVocabViewModel() -> ExploreVocabViewModel {
        return ExploreVocabViewModel(
            fetchVocabsUseCase: makeFetchVocabsUseCase(),
            startQuizUseCase: makeStartQuizUseCase(),
            toggleSaveVocabUseCase: makeToggleSaveVocabUseCase(),
            observeThemeUseCase: makeObserveThemeUseCase()
        )
    }
    
    func makeAddVocabViewModel(editingVocab: Vocab? = nil) -> AddVocabViewModel {
        return AddVocabViewModel(
            addVocabUseCase: makeAddVocabUseCase(),
            updateVocabUseCase: makeUpdateVocabUseCase(),
            editingVocab: editingVocab
        )
    }

    func makeAddVocabUseCase() -> AddVocabUseCase {
        return DefaultAddVocabUseCase(vocabBookRepository: vocabBookRepository)
    }

    func makeUpdateVocabUseCase() -> UpdateVocabUseCase {
        let vocabRepository = makeVocabRepository()
        return DefaultUpdateVocabUseCase(vocabRepository: vocabRepository)
    }
}

// MARK: - Library
extension AppDIContainer {
    func makeLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(fetchVocabBooksUseCase: makeFetchVocabBooksUseCase())
    }

    func makeVocabDetailViewModel(topic: BookTopic) -> VocabBookDetailViewModel {
        return VocabBookDetailViewModel(
            topic: topic,
            fetchVocabsUseCase: makeFetchVocabsUseCase(),
            toggleSaveVocabUseCase: makeToggleSaveVocabUseCase(),
            deleteVocabUseCase: makeDeleteVocabUseCase(),
            setActiveBookUseCase: makeSetActiveBookUseCase(),
            isActiveBookUseCase: makeIsActiveBookUseCase()
        )
    }

    func makeFetchVocabsUseCase() -> FetchVocabsUseCase {
        let learningHistoryRepository = makeVocabLearningHistoryRepository()
        return DefaultFetchVocabsUseCase(
            vocabBookRepository: vocabBookRepository,
            learningHistoryRepository: learningHistoryRepository
        )
    }

    func makeToggleSaveVocabUseCase() -> ToggleSaveVocabUseCase {
        let vocabRepository = makeVocabRepository()
        return DefaultToggleSaveVocabUseCase(
            vocabBookRepository: vocabBookRepository,
            vocabRepository: vocabRepository
        )
    }

    func makeDeleteVocabUseCase() -> DeleteVocabUseCase {
        return DefaultDeleteVocabUseCase(vocabRepository: makeVocabRepository())
    }

    func makeSetActiveBookUseCase() -> SetActiveBookUseCase {
        return DefaultSetActiveBookUseCase(vocabBookRepository: vocabBookRepository)
    }

    func makeIsActiveBookUseCase() -> IsActiveBookUseCase {
        return DefaultIsActiveBookUseCase(vocabBookRepository: vocabBookRepository)
    }

    func makeFetchVocabBooksUseCase() -> FetchVocabBooksUseCase {
        return DefaultFetchVocabBooksUseCase(vocabBookRepository: vocabBookRepository)
    }
}

// MARK: - Quiz
extension AppDIContainer {
    func makeQuizViewModel(quizData: QuizData) -> QuizViewModel {
        return QuizViewModel(
            earnExperienceUseCase: makeEarnExperienceUseCase(),
            studyReminderUseCase: makeStudyReminderUseCase(),
            quizData: quizData
        )
    }

    func makeEarnExperienceUseCase() -> EarnExperienceUseCase {
        return DefaultEarnExperienceUseCase(
            learningHistoryRepository: makeVocabLearningHistoryRepository(),
            petRepository: petRepository
        )
    }
    
    func makeCompleteQuizViewModel(result: QuizResult) -> CompleteQuizViewModel {
        return CompleteQuizViewModel(result: result)
    }

    func makeStartQuizUseCase() -> StartQuizUseCase {
        return DefaultStartQuizUseCase(
            vocabBookRepository: vocabBookRepository,
            learningHistoryRepository: makeVocabLearningHistoryRepository()
        )
    }
}

// MARK: - Setting Tab
extension AppDIContainer {
    func makeSearchThemeRepository() -> SearchThemeRepository {
        return DefaultSearchThemeRepository(apiClient: apiClient)
    }

    func makeSearchThemeUseCase() -> SearchThemeUseCase {
        return DefaultSearchThemeUseCase(repository: makeSearchThemeRepository())
    }
    
    func makeSearchThemeViewModel() -> SearchThemeViewModel {
        return SearchThemeViewModel(
            searchThemeUseCase: makeSearchThemeUseCase(),
            saveThemeUseCase: makeSaveThemeUseCase()
        )
    }

    func makeSaveThemeUseCase() -> SaveThemeUseCase {
        return DefaultSaveThemeUseCase(userInfo: userInfoManager)
    }

    func makeObserveThemeUseCase() -> ObserveThemeUseCase {
        return DefaultObserveThemeUseCase(userInfo: userInfoManager)
    }
}

// MARK: - Weather
extension AppDIContainer {
    func makeWeatherRepository() -> WeatherRepository {
        return DefaultWeatherRepository(apiClient: apiClient)
    }

    /// DeviceLocationProvider가 @MainActor라 생성도 메인에서만 가능하다
    @MainActor
    func makeLocationProvider() -> LocationProviding {
        return DeviceLocationProvider()
    }

    @MainActor
    func makeFetchCurrentWeatherUseCase() -> FetchCurrentWeatherUseCase {
        return DefaultFetchCurrentWeatherUseCase(
            locationProvider: makeLocationProvider(),
            weatherRepository: makeWeatherRepository()
        )
    }
}

// MARK: - Onboarding
extension AppDIContainer {
    func makeOnboardingInterestViewModel() -> OnboardingInterestViewModel {
        return OnboardingInterestViewModel(setActiveBookUseCase: makeSetActiveBookUseCase())
    }

    func makeOnboardingPetNameViewModel(petType: PetType) -> OnboardingPetNameViewModel {
        return OnboardingPetNameViewModel(
            createPetUseCase: makeCreatePetUseCase(),
            petType: petType
        )
    }

    /// 온보딩 재진입 분기(AppFlowCoordinator·OnboardingCoordinator)에서만 쓴다.
    func makeIsPetCreatedUseCase() -> IsPetCreatedUseCase {
        return DefaultIsPetCreatedUseCase(petRepository: petRepository)
    }
}

// MARK: - EggSelection
extension AppDIContainer {
    func makeEggSelectionViewModel() -> EggSelectionViewModel {
        return EggSelectionViewModel()
    }
}


extension AppDIContainer {
    func makeAppEnvProvider() -> AppEnvProvider {
        return DefaultAppEnvProvider()
    }
    
    func makeSettingTabViewModel() -> SettingTabViewModel {
        let envProvider = makeAppEnvProvider()
        return SettingTabViewModel(
            appEnv: envProvider,
            studyReminderUseCase: makeStudyReminderUseCase()
        )
    }

}

// MARK: - Notification
extension AppDIContainer {
    func makeLocalNotificationScheduler() -> LocalNotificationScheduling {
        return LocalNotificationScheduler()
    }

    func makeStudyReminderUseCase() -> StudyReminderUseCase {
        return DefaultStudyReminderUseCase(
            userInfo: userInfoManager,
            learningHistoryRepository: makeVocabLearningHistoryRepository(),
            scheduler: makeLocalNotificationScheduler()
        )
    }
}

extension AppDIContainer {
    func makeVocabRepository() -> VocabRepository {
        return DefaultVocabRepository(context: coreDataStack.viewContext)
    }

    func makeVocabLearningHistoryRepository() -> LearningHistoryRepository {
        return DefaultLearningHistoryRepository(context: coreDataStack.viewContext)
    }
}

// MARK: - Character
extension AppDIContainer {
    func makeCharacterViewModel() -> CharacterViewModel {
        return CharacterViewModel(
            fetchPetStateUseCase: makeFetchPetStateUseCase(),
            carePetUseCase: makeCarePetUseCase(),
            levelUpPetUseCase: makeLevelUpPetUseCase(),
            adjustPetLevelUseCase: makeAdjustPetLevelUseCase(),
            revivePetUseCase: makeRevivePetUseCase()
        )
    }

    func makeFetchPetStateUseCase() -> FetchPetStateUseCase {
        return DefaultFetchPetStateUseCase(petRepository: petRepository)
    }

    func makeCarePetUseCase() -> CarePetUseCase {
        return DefaultCarePetUseCase(petRepository: petRepository)
    }

    func makeLevelUpPetUseCase() -> LevelUpPetUseCase {
        return DefaultLevelUpPetUseCase(petRepository: petRepository)
    }

    /// dev 빌드 테스트 버튼용 — 요구 경험치를 건너뛴다
    func makeAdjustPetLevelUseCase() -> AdjustPetLevelUseCase {
        return DefaultAdjustPetLevelUseCase(petRepository: petRepository)
    }

    func makeRevivePetUseCase() -> RevivePetUseCase {
        return DefaultRevivePetUseCase(petRepository: petRepository)
    }

    func makeCreatePetUseCase() -> CreatePetUseCase {
        return DefaultCreatePetUseCase(petRepository: petRepository)
    }
}
