import Foundation

/// 앱 화면 모드. rawValue는 저장값이라 바꾸면 안 되고, 선언 순서가 설정 화면 세그먼트 순서다.
enum AppearanceMode: Int, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return String(localized: "시스템")
        case .light: return String(localized: "라이트")
        case .dark: return String(localized: "다크")
        }
    }
}
