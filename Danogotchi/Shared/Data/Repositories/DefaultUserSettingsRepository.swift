import Foundation

final class DefaultUserSettingsRepository: UserSettingsRepository {
    private enum Keys {
        static let themeUrl = "themeUrl"
        static let themeImageFileName = "themeImageFileName"
        static let studyReminder = "studyReminderEnabled"
        static let appearanceMode = "appearanceMode"
    }

    private let defaults: UserDefaults
    private let themeImageFileNameBroadcaster = AsyncBroadcaster<String?>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // 저장된 값으로 출발시킨다 — nil에서 시작하면 구독 직후 nil이 흘러 화면이 비워진다
    var themeImageFileNameChanges: AsyncStream<String?> {
        return themeImageFileNameBroadcaster.stream(current: { self.currentThemeImageFileName })
    }

    var currentThemeUrl: String? {
        get { defaults.string(forKey: Keys.themeUrl) }
        set { defaults.set(newValue, forKey: Keys.themeUrl) }
    }

    var currentThemeImageFileName: String? {
        get { defaults.string(forKey: Keys.themeImageFileName) }
        set {
            defaults.set(newValue, forKey: Keys.themeImageFileName)
            themeImageFileNameBroadcaster.send(newValue)
        }
    }

    // 키가 없는 첫 실행은 켜진 것으로 본다 — UserDefaults.bool 기본값(false)을 쓰면 기능이 꺼진 채 시작한다
    var isStudyReminderEnabled: Bool {
        get { defaults.object(forKey: Keys.studyReminder) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.studyReminder) }
    }

    // 키가 없는 첫 실행은 0(.system)으로 읽혀 시스템 설정을 따른다
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: defaults.integer(forKey: Keys.appearanceMode)) ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Keys.appearanceMode) }
    }
}
