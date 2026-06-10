import UIKit

protocol AppEnvProvider {
    var appVersion: String { get }
    var appVersionDisplay: String { get }
    var deviceModel: String { get }
    var systemVersion: String { get }
}

struct DefaultAppEnvProvider: AppEnvProvider {
    let appVersion: String
    let appVersionDisplay: String
    let deviceModel: String
    let systemVersion: String
    
    init() {
        let rawVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "N/A"
        self.appVersion = rawVersion
        self.appVersionDisplay = rawVersion == "N/A" ? "N/A" : "v \(rawVersion)"
        self.deviceModel = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
    }
}
