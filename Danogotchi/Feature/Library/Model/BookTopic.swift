import Foundation

enum BookTopic: CaseIterable, Hashable {
    case myBook
    case travel
    case emotion
    case life
    case business
    
    var title: String {
        switch self {
        case .myBook:
            return "My Vocabulary"
        case .travel:
            return "Travel"
        case .emotion:
            return "Emotion"
        case .life:
            return "Life"
        case .business:
            return "Business"
        }
    }
}
