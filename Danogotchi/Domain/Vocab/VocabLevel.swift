import Foundation

enum VocabLevel: String, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var title: String {
        switch self {
        case .a1:
            return "Beginner"
        case .a2:
            return "Elementary"
        case .b1:
            return "Intermediate"
        case .b2:
            return "Upper Intermediate"
        case .c1:
            return "Advanced"
        case .c2:
            return "Fluent"
        }
    }
}
