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

// MARK: - Word
extension AppDIContainer {
    
    func makeWordRepository() -> WordRepository {
        return DefaultWordRepository()
    }
    
    func makeExploreVocabViewModel() -> ExploreVocabViewModel {
        let wordRepository = makeWordRepository()
        let learnHistoryRepository = makeLearningHistoryRepository()
        return ExploreVocabViewModel(
            wordRepository: wordRepository,
            learnHistoryRepository: learnHistoryRepository
        )
    }
    
    func makeCreateWordViewModel(wordItem: CreateWord) -> CreateWordViewModel {
        let wordRepository = makeWordRepository()
        let wordBookRepository = makeWordBookRepository()
        return CreateWordViewModel(
            wordItem: wordItem,
            wordBookRepository: wordBookRepository,
            wordRepository: wordRepository
        )
    }
}

// MARK: - Library
extension AppDIContainer {
    func makeWordBookRepository() -> WordBookRepository {
        return DefaultWordBookRepository()
    }
    
    func makeRecommendBookRepository() -> RecommendBookRepository {
        return DefaultRecommendBookRepository()
    }
    
    func makeLibraryViewModel() -> LibraryViewModel {
        let wordBookRepository = makeWordBookRepository()
        let recommendBookRepository = makeRecommendBookRepository()
        let wordRepository = makeWordRepository()

        return LibraryViewModel(
            recommendBookRepository: recommendBookRepository,
            wordBookRepository: wordBookRepository,
            wordRepository: wordRepository
        )
    }
    
    func makeMyBookDetailViewModel() -> MyBookDetailViewModel {
        let wordBookRepository = makeWordBookRepository()
        let wordRepository = makeWordRepository()
        let learningHistoryRepository = makeLearningHistoryRepository()
        return MyBookDetailViewModel(
            wordBookRepository: wordBookRepository,
            wordRepository: wordRepository,
            learningHistoryRepository: learningHistoryRepository
        )
    }
}

// MARK: - Quiz
extension AppDIContainer {
    func makeLearningHistoryRepository() -> LearningHistoryRepository {
        return DefaultLearningHistoryRepository()
    }
    
    func makeQuizViewModel(quizData: QuizData) -> QuizViewModel {
        let learningHistoryRepository = makeLearningHistoryRepository()
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
