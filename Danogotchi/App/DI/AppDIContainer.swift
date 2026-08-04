import Foundation

final class AppDIContainer {
    // MARK: - Managers
    let userInfoManager: UserInfoManager
    let ttsManager: TTSManager
    let activeLearningManager: ActiveLearningManager
    let coreDataStack: CoreDataStack
    
    init() {
        userInfoManager = UserInfoManager.shared
        ttsManager = TTSManager.shared
        activeLearningManager = ActiveLearningManager.shared
        coreDataStack = CoreDataStack.shared
    }
}

// MARK: - Explore / CreateWord
extension AppDIContainer {

    func makeExploreVocabViewModel() -> ExploreVocabViewModel {
        let learnHistoryRepository = makeVocabLearningHistoryRepository()
        return ExploreVocabViewModel(
            learnHistoryRepository: learnHistoryRepository
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
        let vocabBookRepository = makeVocabBookRepository()
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
        return LibraryViewModel()
    }

    func makeVocabDetailViewModel(topic: BookTopic) -> VocabBookDetailViewModel {
        return VocabBookDetailViewModel(
            topic: topic,
            fetchVocabsUseCase: makeFetchVocabsUseCase(),
            toggleSaveVocabUseCase: makeToggleSaveVocabUseCase(),
            deleteVocabUseCase: makeDeleteVocabUseCase()
        )
    }

    func makeFetchVocabsUseCase() -> FetchVocabsUseCase {
        let vocabBookRepository = makeVocabBookRepository()
        let learningHistoryRepository = makeVocabLearningHistoryRepository()
        return DefaultFetchVocabsUseCase(
            vocabBookRepository: vocabBookRepository,
            learningHistoryRepository: learningHistoryRepository
        )
    }

    func makeToggleSaveVocabUseCase() -> ToggleSaveVocabUseCase {
        let vocabBookRepository = makeVocabBookRepository()
        let vocabRepository = makeVocabRepository()
        return DefaultToggleSaveVocabUseCase(
            vocabBookRepository: vocabBookRepository,
            vocabRepository: vocabRepository
        )
    }

    func makeDeleteVocabUseCase() -> DeleteVocabUseCase {
        return DefaultDeleteVocabUseCase(vocabRepository: makeVocabRepository())
    }
}

// MARK: - Quiz
extension AppDIContainer {
    func makeQuizViewModel(quizData: QuizData) -> QuizViewModel {
        let learningHistoryRepository = makeVocabLearningHistoryRepository()
        return QuizViewModel(
            learningHistoryRepository: learningHistoryRepository,
            quizData: quizData
        )
    }
    
    func makeCompleteQuizViewModel(result: QuizResult) -> CompleteQuizViewModel {
        return CompleteQuizViewModel(result: result)
    }
}

// MARK: - Setting Tab
extension AppDIContainer {
    func makeSearchThemeRepository() -> SearchThemeRepository {
        return DefaultSearchThemeRepository()
    }
    
    func makeSearchThemeViewModel(mode: SearchThemeViewController.EntryMode) -> SearchThemeViewModel {
        let repository = makeSearchThemeRepository()
        return SearchThemeViewModel(
            mode: mode,
            repository: repository
        )
    }
}


extension AppDIContainer {
    func makeAppEnvProvider() -> AppEnvProvider {
        return DefaultAppEnvProvider()
    }
    func makeSettingTabViewModel() -> SettingTabViewModel {
        let envProvider = makeAppEnvProvider()
        return SettingTabViewModel(appEnv: envProvider)
    }
    
}

extension AppDIContainer {
    func makeVocabRepository() -> VocabRepository {
        return DefaultVocabRepository(context: coreDataStack.viewContext)
    }

    func makeVocabBookRepository() -> VocabBookRepository {
        return DefaultVocabBookRepository(context: coreDataStack.viewContext)
    }

    func makeVocabLearningHistoryRepository() -> LearningHistoryRepository {
        return DefaultLearningHistoryRepository(context: coreDataStack.viewContext)
    }
}
