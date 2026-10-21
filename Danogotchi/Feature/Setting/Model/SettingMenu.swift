import Foundation

struct SettingMenu: Hashable {
    enum Category: CaseIterable, CustomStringConvertible {
        case general
        case support
        case info
        
        var description: String {
            switch self {
            case .general: return String(localized: "일반")
            case .support: return String(localized: "지원 및 피드백")
            case .info: return String(localized: "앱 정보")
            }
        }
        
        var list: [SettingMenu] {
            switch self {
            case .general:
                return [
                    SettingMenu(icon: "🔔", title: String(localized: "학습 알림"),
                                category: self, action: .studyReminder),
                    SettingMenu(icon: "🎨", title: String(localized: "배경 테마 변경하기"),
                                category: self, action: .searchTheme)
                ]
            case .support:
                return [
                    SettingMenu(icon: "✉️", title: String(localized: "문의하기"),
                                category: self, action: .inquiry),
                    SettingMenu(icon: "⭐️", title: String(localized: "앱스토어 리뷰"),
                                category: self, action: .appStore)
                ]
            case .info:
                return [
                    SettingMenu(icon: "🔒", title: String(localized: "개인정보 처리방침"),
                                category: self, action: .privacyPolicy),
                    SettingMenu(icon: "🏷️", title: String(localized: "앱 버전"), category: self,
                                action: .appVersion)
                ]
            }
        }
    }
    
    enum Action {
        case studyReminder
        case searchTheme
        case inquiry
        case appStore
        case privacyPolicy
        case appVersion
    }
    
    private let id = UUID()
    let icon: String
    let title: String
    let category: Category
    let action: Action
}
