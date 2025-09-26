import Foundation

protocol UserInfoProtocol {
    var username: String? { get set }
}

final class UserInfoManager: UserInfoProtocol {
    private init() { }
    
    static let shared = UserInfoManager()
    
    private enum Keys {
        static let username = "username"
    }
    
    var username: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.username)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.username)
        }
    }
}
