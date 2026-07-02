import UIKit

enum AppFont {
    
    enum Weight: String {
        case regular = "Pretendard-Regular"
        case medium = "Pretendard-Medium"
        case semibold = "Pretendard-SemiBold"
        case bold = "Pretendard-Bold"
    }
    
    static func font(_ weight: Weight, size: CGFloat) -> UIFont {
        return UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: weight.systemFallback)
    }
    
    static var display: UIFont { font(.bold, size: 28) }
    static var title1: UIFont { font(.bold, size: 24) }
    static var title2: UIFont { font(.semibold, size: 20) }
    static var title3: UIFont { font(.semibold, size: 18) }
    static var headline: UIFont { font(.semibold, size: 17) }
    static var body: UIFont { font(.regular, size: 16) }
    static var bodyEmphasis: UIFont { font(.semibold, size: 16) }
    static var label: UIFont { font(.medium,   size: 14) }
    static var footnote: UIFont { font(.regular,  size: 14) }
    static var caption: UIFont { font(.regular,  size: 10) }
}


private extension AppFont.Weight {
    var systemFallback: UIFont.Weight {
        switch self {
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        }
    }
}
