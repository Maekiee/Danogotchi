import Foundation
import RxSwift
import RxCocoa


final class UserInfoManager: UserInfoProtocol {
    private init() {
        // UserDefaults에서 초기값 로드
        if let savedId = UserDefaults.standard.string(forKey: Keys.wordBookId) {
            selectedBookIdRelay.accept(savedId)
        }
    }
    
    static let shared = UserInfoManager()
    
    private enum Keys {
        static let username = "username"
        static let userId = "userId"
        static let wordBookId = "WordBookId"
        static let currentQuizWordIds = "currentQuizWordIds"
        static let currentQuizIndex = "currentQuizIndex"
        static let currentCorrectCount = "currentCorrectCount"
        static let currentIncorrectWordIds = "currentIncorrectWordIds"
    }
    
    private let selectedBookIdRelay = BehaviorRelay<String?>(value: nil)
    var selectedBookIdObservable: Observable<String?> {
        return selectedBookIdRelay.asObservable()
    }
    
    var username: String? {
        get {
            guard let username = UserDefaults.standard.string(forKey: Keys.username) else { return nil }
            return username
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.username)
        }
    }
    
    // 아직 사용 안함
    var userId: String? {
        get {
            guard let userId = UserDefaults.standard.string(forKey: Keys.userId) else { return nil }
            return userId
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.userId)
        }
    }
    
    var selectedBookId: String? {
        get {
            return selectedBookIdRelay.value
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.wordBookId)
            selectedBookIdRelay.accept(newValue)
        }
    }
    
    var currentCorrectCount: Int {
        get {
            UserDefaults.standard.integer(forKey: Keys.currentCorrectCount)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.currentCorrectCount)
        }
    }
    
    var currentIncorrectWordIds: [String]? {
        get {
            UserDefaults.standard.array(forKey: Keys.currentIncorrectWordIds) as? [String]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.currentIncorrectWordIds)
        }
    }
    
    // 현제퀴즈 단어 아이디 배열
    var currentQuizWordIds: [String]? {
        get {
            UserDefaults.standard.array(forKey: Keys.currentQuizWordIds) as? [String]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.currentQuizWordIds)
        }
    }
    
    var currentQuizIndex: Int {
        get {
            UserDefaults.standard.integer(forKey: Keys.currentQuizIndex)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.currentQuizIndex)
        }
    }
    
    
    // 아직 사용 안함
    func removeUserInfo() {
        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
        UserDefaults.standard.removeObject(forKey: Keys.wordBookId)
        selectedBookIdRelay.accept(nil)
    }
    
    func clearQuizState() {
        UserDefaults.standard.removeObject(forKey: Keys.currentQuizWordIds)
        UserDefaults.standard.removeObject(forKey: Keys.currentQuizIndex)
        UserDefaults.standard.removeObject(forKey: Keys.currentCorrectCount)
        UserDefaults.standard.removeObject(forKey: Keys.currentIncorrectWordIds)
    }
}
