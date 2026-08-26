import Foundation
import RxSwift
import RxCocoa


final class UserInfoManager: UserInfoProtocol {
    private enum Keys {
        static let username = "username"
        static let userId = "userId"
        static let themeUrl = "themeUrl"
        static let studyReminder = "studyReminderEnabled"
    }

    private let themeUrlRelay = BehaviorRelay<String?>(value: nil)

    var themeUrlObservable: Observable<String?> {
        return themeUrlRelay.asObservable()
    }

    static let shared = UserInfoManager()

    private init () { }

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
    
    // 키가 없는 첫 실행은 켜진 것으로 본다 — UserDefaults.bool 기본값(false)을 쓰면 기능이 꺼진 채 시작한다
    var isStudyReminderEnabled: Bool {
        get {
            return UserDefaults.standard.object(forKey: Keys.studyReminder) as? Bool ?? true
        }

        set {
            UserDefaults.standard.set(newValue, forKey: Keys.studyReminder)
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
        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
    }
}
