import UIKit

extension AppearanceMode {
    /// 창에 걸 오버라이드 값. 시스템은 오버라이드를 풀어 기기 설정을 따른다
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// 설정 세그먼트 아이콘. 글자 대신 쓰므로 VoiceOver용 이름을 붙인다
    var icon: UIImage? {
        let name: String
        switch self {
        case .system: name = "circle.lefthalf.filled"
        case .light: name = "sun.max"
        case .dark: name = "moon"
        }
        let image = UIImage(systemName: name)
        image?.accessibilityLabel = title
        return image
    }
}
