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
}

// MARK: - Quiz
extension DIContainer {
    func makeLearningHistoryRepository() -> LearningHistoryRepositoryProtocol {
        return LearningHistoryRepository()
    }
}

// MARK: - Setting
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
