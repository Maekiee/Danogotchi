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
    
    func makeCreateWordViewModel(vocabItem: CreateVocab) -> CreateWordViewModel {
        let vocabRepository = makeVocabRepository()
        let vocabBookRepository = makeVocabBookRepository()
        return CreateWordViewModel(
            vocabItem: vocabItem,
            vocabBookRepository: vocabBookRepository,
            vocabRepository: vocabRepository
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
        let vocabBookRepository = makeVocabBookRepository()
        let recommendBookRepository = makeRecommendBookRepository()

        return LibraryViewModel(
            recommendBookRepository: recommendBookRepository,
            vocabBookRepository: vocabBookRepository
        )
    }
    
    func makeMyBookDetailViewModel() -> MyBookDetailViewModel {
        let vocabBookRepository = makeVocabBookRepository()
        let vocabRepository = makeVocabRepository()
        let learningHistoryRepository = makeVocabLearningHistoryRepository()
        return MyBookDetailViewModel(
            vocabBookRepository: vocabBookRepository,
            vocabRepository: vocabRepository,
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

extension AppDIContainer {
    func makeVocabRepository() -> VocabRepository {
        return DefaultVocabRepository(context: coreDataStack.viewContext)
    }

    func makeVocabBookRepository() -> VocabBookRepository {
        return DefaultVocabBookRepository(context: coreDataStack.viewContext)
    }

    func makeVocabLearningHistoryRepository() -> VocabLearningHistoryRepository {
        return DefaultVocabLearningHistoryRepository(context: coreDataStack.viewContext)
    }
}
