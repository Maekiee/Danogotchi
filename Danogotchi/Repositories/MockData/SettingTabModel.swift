import Foundation


struct Setting: Hashable {
    
    enum Category: CaseIterable, CustomStringConvertible {
        case general
        case statistic
        case support
        case info
    }
    
    let icon: String
    let title: String
    let category: Category
    private let id = UUID()
}


extension Setting.Category {
    
    var description: String {
        switch self {
        case .general: return "일반"
        case .statistic: return "학습 통계"
        case .support: return "지원 및 피드백"
        case .info: return "앱 정보"
        }
    }
    
    var list: [Setting] {
        switch self {
        case .general:
            return [
                Setting(icon: "🎨", title: "배경 테마 변경하기", category: self)
            ]
        case .statistic:
            return [
                Setting(icon: "📜", title: "학습 히스토리", category: self),
//                Setting(icon: "🧮", title: "전체 학습 단어", category: self),
//                Setting(icon: "🎯", title: "정오답 비율", category: self),
            ]
        case .support:
            return [
                Setting(icon: "✉️", title: "문의하기", category: self),
                Setting(icon: "⭐️", title: "앱스토어 리뷰", category: self),
            ]
        case .info:
            return [
                Setting(icon: "👾", title: "오픈소스 라이선스", category: self),
                Setting(icon: "🔒", title: "개인정보 처리방침", category: self),
                Setting(icon: "🏷️", title: "앱 버전", category: self),
            ]
        }
    }
}


