import SwiftUI

// 주제·품사 id의 표시 이름
extension StudyStatsCategoryKind {
    func title(for id: String?) -> String {
        switch identifier(id) {
        case "travel": return String(localized: "여행")
        case "business": return String(localized: "비즈니스")
        case "emotion": return String(localized: "감정")
        case "life": return String(localized: "일상")
        case "noun": return String(localized: "명사")
        case "verb": return String(localized: "동사")
        case "adj": return String(localized: "형용사")
        case "adv": return String(localized: "부사")
        default: return String(localized: "미분류")
        }
    }
}
