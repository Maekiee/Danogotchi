import UIKit

enum AppColor {

    // MARK: - Palette (Assets 컬러셋과 1:1, 원시 토큰)
    static let coral = named("coral")
    static let sage = named("sage")
    static let sky = named("sky")
    static let lavender = named("lavender")
    static let butter = named("butter")
    static let ocean = named("ocean")

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
    static let textSecondary = dynamic(light: gray75, dark: gray45)
    static let card = dynamic(light: white, dark: surfaceDark)                 // 설정 셀·입력 칸
    static let surface = dynamic(light: appWhite, dark: surfaceDark)           // 퀴즈 카드·버튼 면
    static let groupedBackground = dynamic(light: appWhite, dark: background)  // 설정 목록 바탕
    static let outline = dynamic(light: .black, dark: textPrimary)             // 카드 테두리
    static let inverse = dynamic(light: black, dark: textPrimary)              // 채운 버튼 바탕
    static let onInverse = dynamic(light: white, dark: background)             // 채운 버튼 글자
    static let primary = ocean    // ← 디자인 확정 후 조정
    static let error = appRed

    // MARK: - Legacy
    static let appWhite = UIColor(red: 0.9608, green: 0.949,  blue: 0.9216, alpha: 1.0)
    static let appGreen = UIColor(red: 0.6314, green: 0.8275, blue: 0.4314, alpha: 1.0)
    static let appRed = UIColor(red: 0.8824, green: 0.298, blue: 0.3333, alpha: 1.0)

    // MARK: - Dark
    private static let surfaceDark = UIColor(red: 0.1686, green: 0.1529, blue: 0.1255, alpha: 1.0)  // #2B2720

    // MARK: - Derived
    static func pastel(for seed: String) -> UIColor {
        UIColor(
            hue: CGFloat(abs(seed.hashValue % 300)) / 360.0,
            saturation: 0.30,
            brightness: 0.95,
            alpha: 1.0
        )
    }

    // MARK: - Helper
    // 동적 컬러를 넘겨도 같은 trait로 한 번 더 풀어 준다
    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { trait in
            (trait.userInterfaceStyle == .dark ? dark : light).resolvedColor(with: trait)
        }
    }

    private static func named(_ name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Assets에 '\(name)' 컬러셋이 없습니다")
            return .systemPink
        }
        return color
    }
}
