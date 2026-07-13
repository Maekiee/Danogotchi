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
    
    func makeCreateWordViewModel(vocabItem: CreateVocab) -> CreateVocabViewModel {
        let vocabRepository = makeVocabRepository()
        let vocabBookRepository = makeVocabBookRepository()
        return CreateVocabViewModel(
            vocabItem: vocabItem,
            vocabBookRepository: vocabBookRepository,
            vocabRepository: vocabRepository
        )
    }
}

// MARK: - Library
extension AppDIContainer {
    func makeRecommendBookRepository() -> RecommendBookRepository {
        return DefaultRecommendBookRepository()
    }
    
    func makeLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel()
    }
    
    func makeOldLibraryViewModel() -> OldLibraryViewModel {
        let vocabBookRepository = makeVocabBookRepository()
        let recommendBookRepository = makeRecommendBookRepository()

        return OldLibraryViewModel(
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
    
    func makeVocabDetailViewModel(topic: BookTopic) -> VocabBookDetailViewModel {
        return VocabBookDetailViewModel(topic: topic)
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
