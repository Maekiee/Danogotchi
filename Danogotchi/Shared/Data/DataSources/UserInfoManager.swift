import Foundation
import RxSwift
import RxCocoa


final class UserInfoManager: UserInfoProtocol {
    private enum Keys {
        static let username = "username"
        static let userId = "userId"
        static let activeBookId = "activeBookId"
        static let themeUrl = "themeUrl"
    }

    // `ActiveLearningManager`가 구독할 Relay
    let activeBookIdentifierRelay: BehaviorRelay<UUID?>
    private let themeUrlRelay = BehaviorRelay<String?>(value: nil)

    var themeUrlObservable: Observable<String?> {
        return themeUrlRelay.asObservable()
    }

    static let shared = UserInfoManager()

    private init () {
        self.activeBookIdentifierRelay = BehaviorRelay<UUID?>(
            value: UserDefaults.standard.string(forKey: Keys.activeBookId)
                .flatMap(UUID.init(uuidString:))
        )
    }

    var activeBookIdentifier: UUID? {
        get {
            UserDefaults.standard.string(forKey: Keys.activeBookId)
                .flatMap(UUID.init(uuidString:))
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: Keys.activeBookId)
            activeBookIdentifierRelay.accept(newValue)
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
    
    // 아직 사용 안함
    func removeUserInfo() {
        activeBookIdentifier = nil

        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
    }
}
