import Foundation

/// 익명 설치 ID의 생성과 조회는 이 타입에서만 한다 — 나중에 Amplitude userId에도 이 값을 쓴다
final class DefaultInstallationIDRepository: InstallationIDRepository {
    // 키 문자열을 바꾸면 기존 설치의 ID가 새로 만들어진다
    private static let key = "installationID"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// IDFA·IDFV 같은 기기 식별자가 아니라 무작위 UUID다
    var installationID: String {
        if let saved = defaults.string(forKey: Self.key) { return saved }
        let created = UUID().uuidString
        defaults.set(created, forKey: Self.key)
        return created
    }
}
