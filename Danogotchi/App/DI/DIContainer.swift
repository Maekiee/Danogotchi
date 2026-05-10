import Foundation

final class DIContainer {
    // MARK: - Managers
    let userInfoManager: UserInfoManager
    let ttsManager: TTSManager
    let activeLearningManager: ActiveLearningManager
    
    init() {
        userInfoManager = UserInfoManager.shared
        ttsManager = TTSManager.shared
        activeLearningManager = ActiveLearningManager.shared
    }
}

// MARK: - Word
extension DIContainer {
    
    func makeWordRepository() -> WordRepositoryProtocol {
        return WordRepository()
    }
    
    func makeWordTabViewModel() -> WordTabViewModel {
        let wordRepository = makeWordRepository()
        let learnHistoryRepository = makeLearningHistoryRepository()
        return WordTabViewModel(
            wordRepository: wordRepository,
            learnHistoryRepository: learnHistoryRepository
        )
    }
    
    func makeAddWordViewModel(wordItem: CreateWord) -> AddWordViewModel {
        let wordRepository = makeWordRepository()
        let wordBookRepository = makeWordBookRepository()
        return AddWordViewModel(
            wordItem: wordItem,
            wordBookRepository: wordBookRepository,
            wordRepository: wordRepository
        )
    }
}

// MARK: - Library
extension DIContainer {
    func makeWordBookRepository() -> WordBookRepositoryProtocol {
        return WordBookRepository()
    }
    
    func makeRecommendBookRepository() -> RecommendBookRepoProtocol {
        return RecommendBookRepository()
    }
    
    func makeBookListViewModel() -> BookListViewModel {
        let wordBookRepository = makeWordBookRepository()
        let recommendBookRepository = makeRecommendBookRepository()
        let wordRepository = makeWordRepository()
        
        return BookListViewModel(
            recommendBookRepository: recommendBookRepository,
            wordBookRepository: wordBookRepository,
            wordRepository: wordRepository
        )
    }
    
    // -- 추가 --
    
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
    
    func makeCreateBookViewModel() -> CreateBookViewModel {
        let wordBookRepository = makeWordBookRepository()
        return CreateBookViewModel(
            wordBookRepository: wordBookRepository
        )
    }
}

// MARK: - Quiz
extension DIContainer {
    func makeLearningHistoryRepository() -> LearningHistoryRepositoryProtocol {
        return LearningHistoryRepository()
    }
}

// MARK: - Setting Tab
extension DIContainer {
    func makeSearchThemeRepository() -> SearchThemeRepoProtocol {
        return SearchThemeRepository()
    }
    
    func makeSearchThemeViewModel(mode: SearchThemeViewController.EntryMode) -> SearchThemeViewModel {
        let repository = makeSearchThemeRepository()
        return SearchThemeViewModel(
            mode: mode,
            repository: repository
        )
    }
}


extension DIContainer {
    
    func makeSettingTabViewModel() -> SettingTabViewModel {
        return SettingTabViewModel()
    }
    
}
