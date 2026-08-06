import Foundation

final class AppDIContainer {
    // MARK: - Managers
    let userInfoManager: UserInfoManager
    let ttsManager: TTSManager
    let coreDataStack: CoreDataStack

    /// 활성 단어장 변경 신호를 보유하므로 앱 전체에서 인스턴스가 하나여야 한다.
    lazy var vocabBookRepository: VocabBookRepository = DefaultVocabBookRepository(
        context: coreDataStack.viewContext
    )

    init() {
        userInfoManager = UserInfoManager.shared
        ttsManager = TTSManager.shared
        coreDataStack = CoreDataStack.shared
    }
}

// MARK: - Explore / CreateWord
extension AppDIContainer {

    func makeExploreVocabViewModel() -> ExploreVocabViewModel {
        let learnHistoryRepository = makeVocabLearningHistoryRepository()
        return ExploreVocabViewModel(
            vocabBookRepository: vocabBookRepository,
            learnHistoryRepository: learnHistoryRepository,
            startQuizUseCase: makeStartQuizUseCase()
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
        let learningHistoryRepository = makeVocabLearningHistoryRepository()
        return QuizViewModel(
            learningHistoryRepository: learningHistoryRepository,
            quizData: quizData
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
        return DefaultSearchThemeRepository()
    }
    
    func makeSearchThemeViewModel(mode: SearchThemeViewController.EntryMode) -> SearchThemeViewModel {
        let repository = makeSearchThemeRepository()
        return SearchThemeViewModel(
            mode: mode,
            repository: repository,
            vocabBookRepository: vocabBookRepository
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

    func makeVocabLearningHistoryRepository() -> LearningHistoryRepository {
        return DefaultLearningHistoryRepository(context: coreDataStack.viewContext)
    }
}
