import Foundation
import RxSwift
import RxCocoa


final class UserInfoManager: UserInfoProtocol {
    
    
    enum ActiveBookType: String {
        case realm
        case recommended
    }
    
    // 활성 단어장 식별자 구조체
    struct ActiveBookIdentifier {
        let id: String
        let type: ActiveBookType
    }
    
    private enum Keys {
        static let username = "username"
        static let userId = "userId"
        
        static let defaultRealmBookIdKey = "WordBookId"
        
        static let activeBookId = "activeBookId"
        static let activeBookType = "activeBookType"
        
        
        static let currentQuizWordIds = "currentQuizWordIds"
        static let currentQuizIndex = "currentQuizIndex"
        static let currentCorrectCount = "currentCorrectCount"
        static let currentIncorrectWordIds = "currentIncorrectWordIds"
        static let themeUrl = "themeUrl"
    }
    
    // `ActiveLearningManager`가 구독할 Relay
    let activeBookIdentifierRelay: BehaviorRelay<ActiveBookIdentifier?>
    
    private let wordBookRefreshRelay = PublishRelay<Void>()
    
    private let themeUrlRelay = BehaviorRelay<String?>(value: nil)
    
    var themeUrlObservable: Observable<String?> {
        return themeUrlRelay.asObservable()
    }
    
    var wordBookRefreshObservable: Observable<Void> {
        return wordBookRefreshRelay.asObservable()
    }
    
    func notifyWordBookUpdate() {
        wordBookRefreshRelay.accept(())
    }
    
    static let shared = UserInfoManager()

    
    private init () {
        UserInfoManager.migrateOldKey()
        
        let initialIdentifier: ActiveBookIdentifier?
        if let id = UserDefaults.standard.string(forKey: Keys.activeBookId),
           let typeRaw = UserDefaults.standard.string(forKey: Keys.activeBookType),
           let type = ActiveBookType(rawValue: typeRaw) {
            initialIdentifier = ActiveBookIdentifier(id: id, type: type)
        } else {
            initialIdentifier = nil
        }
        
        self.activeBookIdentifierRelay = BehaviorRelay<ActiveBookIdentifier?>(value: initialIdentifier)
    }
    
    var activeBookIdentifier: ActiveBookIdentifier? {
        get {
            guard let id = UserDefaults.standard.string(forKey: Keys.activeBookId),
                  let typeRaw = UserDefaults.standard.string(forKey: Keys.activeBookType),
                  let type = ActiveBookType(rawValue: typeRaw) else {
                return nil
            }
            return ActiveBookIdentifier(id: id, type: type)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.id, forKey: Keys.activeBookId)
                UserDefaults.standard.set(newValue.type.rawValue, forKey: Keys.activeBookType)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeBookId)
                UserDefaults.standard.removeObject(forKey: Keys.activeBookType)
            }
            
            activeBookIdentifierRelay.accept(newValue)
        }
    }
    
    
    var selectedBookId: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.defaultRealmBookIdKey)
        }
        set {
            
            UserDefaults.standard.set(newValue, forKey: Keys.defaultRealmBookIdKey)
            
            if let newValue = newValue {
                activeBookIdentifier = ActiveBookIdentifier(id: newValue, type: .realm)
            } else {
                if activeBookIdentifier?.type == .realm {
                    activeBookIdentifier = nil
                }
            }
        }
    }
    
    private static func migrateOldKey() {
        let defaults = UserDefaults.standard
        
        guard defaults.string(forKey: Keys.activeBookId) == nil else {
            return
        }
        
        if let defaultRealmId = defaults.string(forKey: Keys.defaultRealmBookIdKey) {
            defaults.set(defaultRealmId, forKey: Keys.activeBookId)
            defaults.set(ActiveBookType.realm.rawValue, forKey: Keys.activeBookType)
        }
    }
    
    var currentThemeUrl: String? {
        get {
            guard let selectedThemeUrl = UserDefaults.standard.string(forKey: Keys.themeUrl) else { return nil }
            return selectedThemeUrl
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.themeUrl)
            themeUrlRelay.accept(newValue)
        }
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
        activeBookIdentifier = nil
        
        // '기본 내 단어장' ID도 함께 삭제
        UserDefaults.standard.removeObject(forKey: Keys.defaultRealmBookIdKey)
        
        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
    }
    
    func clearQuizState() {
        UserDefaults.standard.removeObject(forKey: Keys.currentQuizWordIds)
        UserDefaults.standard.removeObject(forKey: Keys.currentQuizIndex)
        UserDefaults.standard.removeObject(forKey: Keys.currentCorrectCount)
        UserDefaults.standard.removeObject(forKey: Keys.currentIncorrectWordIds)
    }
}
