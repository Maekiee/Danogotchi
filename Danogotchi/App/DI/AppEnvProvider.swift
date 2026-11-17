import UIKit

protocol AppEnvProvider {
    var appVersion: String { get }
    var appVersionDisplay: String { get }
    var deviceModel: String { get }
    var systemVersion: String { get }
    /// 문의 메일에 적는 익명 설치 ID — Crashlytics userID와 같은 값이라 콘솔에서 찾을 수 있다
    var installationID: String { get }
}

struct DefaultAppEnvProvider: AppEnvProvider {
    let appVersion: String
    let appVersionDisplay: String
    let deviceModel: String
    let systemVersion: String
    let installationID: String

    init(installationID: String) {
        let rawVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "N/A"
        self.appVersion = rawVersion
        self.appVersionDisplay = rawVersion == "N/A" ? "N/A" : "v \(rawVersion)"
        self.deviceModel = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
        self.installationID = installationID
    }
}
