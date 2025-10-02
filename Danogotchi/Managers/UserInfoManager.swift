import Foundation

final class UserInfoManager: UserInfoProtocol {
    private init() { }
    
    static let shared = UserInfoManager()
    
    private enum Keys {
        static let username = "username"
        static let userId = "userId"
        static let wordBookId = "WordBookId"
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
    
    var selectedWordBook: String? {
        get {
            guard let wordBookId = UserDefaults.standard.string(forKey: Keys.wordBookId) else { return nil }
            return wordBookId
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.wordBookId)
        }
    }
    
    // 아직 사용 안함
    func removeUserInfo() {
        UserDefaults.standard.removeObject(forKey: Keys.username)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
    }
}
