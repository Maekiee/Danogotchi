import UIKit
import SwiftUI

enum AppColor {

    // MARK: - Palette (Assets 컬러셋과 1:1, 원시 토큰)
    static let coral = named("coral")
    static let sage = named("sage")
    static let sky = named("sky")
    static let lavender = named("lavender")
    static let butter = named("butter")

    static let white = named("white")
    static let black = named("black")
    static let gray15 = named("gray15")
    static let gray30 = named("gray30")
    static let gray45 = named("gray45")
    static let gray60 = named("gray60")
    static let gray75 = named("gray75")
    static let gray90 = named("gray90")

    // MARK: - Semantic (의미 토큰 — 컴포넌트는 이 레이어만 사용)
    static let background = named("backgroundColor")  // light/dark 자동 대응
    static let textPrimary = named("textColor")        // light/dark 자동 대응
    static let textSecondary = gray75
    static let card = white
    static let primary = coral    // ← 디자인 확정 후 조정

    // MARK: - Legacy (대응 컬러셋 없음 — 점진 교체 전까지 값·이름 유지)
    static let cardColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
    static let primaryColor = UIColor(red: 0.17, green: 0.24, blue: 0.31, alpha: 0.95)
    static let oxfordBlue = UIColor(red: 0, green: 0.1294, blue: 0.2784, alpha: 1.0)
    static let backgroundBeige = UIColor(red: 0.8039, green: 0.7216, blue: 0.6157, alpha: 1.0)
    static let backgroundBeige2 = UIColor(red: 0.7725, green: 0.7294, blue: 0.6667, alpha: 1.0)
    static let pointDarkGray = UIColor(red: 0.251, green: 0.251, blue: 0.251, alpha: 1.0)
    static let appWhite = UIColor(red: 0.9608, green: 0.949,  blue: 0.9216, alpha: 1.0)
    static let appGreen = UIColor(red: 0.6314, green: 0.8275, blue: 0.4314, alpha: 1.0)
    static let appRed = UIColor(red: 0.8824, green: 0.298, blue: 0.3333, alpha: 1.0)
    static let pointBlack = UIColor(red: 0.1451, green: 0.1412, blue: 0.1333, alpha: 1.0)

    // MARK: - Derived (시드 문자열로 파생되는 파스텔 카드 배경)
    /// 같은 문자열이면 같은 색을 돌려준다. (앱 실행 단위 — `hashValue` 시드가 실행마다 달라짐)
    static func pastel(for seed: String) -> UIColor {
        UIColor(
            hue: CGFloat(abs(seed.hashValue % 300)) / 360.0,
            saturation: 0.30,
            brightness: 0.95,
            alpha: 1.0
        )
    }

    // MARK: - Helper
    private static func named(_ name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Assets에 '\(name)' 컬러셋이 없습니다")
            return .systemPink   // 누락 시 눈에 띄게
        }
        return color
    }
}

enum SwiftUIAppColor {
    static let oxfordBlue = Color(red: 0, green: 0.1294, blue: 0.2784)
}
